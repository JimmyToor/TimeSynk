import { Controller } from "@hotwired/stimulus";
import Utility from "../../../lib/util/utility";

// Connects to data-controller="schedule-selection"
export default class extends Controller {
  static targets = [
    "query",
    "frame",
    "form",
    "spinner",
    "scheduleIdInput",
    "scheduleToggle",
    "scheduleName",
    "removeButton",
  ];
  static values = {
    frameId: { type: String, default: "modal_frame" },
  };
  static outlets = ["rails-nested-form", "calendar", "dialog"];

  initialize() {
    this.debouncedCalendarUpdate = Utility.debounceFn(
      () => this.updateCalendar,
      500,
    );
    this.submitSuccessCallback = this.onSubmitSuccess.bind(this);
  }

  //Handles post-creation of a new schedule.
  onSubmitSuccess() {
    if (!this.hasFrameTarget) return;
    // Reload the frame to show the new schedule
    this.frameTarget.src = this.frameTarget.src;

    const availabilityId = this.frameTarget.dataset.availabilityId;
    if (!availabilityId) {
      console.error("No availability ID found in frame target.");
      return;
    }

    // Re-fetch the schedules to ensure the new one is included
    fetch(
      `/availability_schedules.json?availability_id=${this.frameTarget.dataset.availabilityId}?`,
    )
      .then((response) => response.json())
      .then((data) => {
        data.forEach((availabilitySchedule) => {
          // Check for schedules that are not listed in the form and add them
          if (
            this.scheduleIdInputTargets.find(
              (input) =>
                parseInt(input.dataset.scheduleId) ===
                availabilitySchedule.schedule.id,
            )
          )
            return;
          // RailsNestedFormOutlet needs an event to add the new schedule.
          let event = this.makeHollowEvent({
            value: {
              dataset: {
                scheduleId: availabilitySchedule.schedule_id,
                scheduleName: availabilitySchedule.schedule.name,
                recordId: availabilitySchedule.id,
              },
            },
          });

          this.addSchedule(event, true);
        });
      });
  }

  toggleSchedule(event) {
    if (event.target.checked) {
      this.addSchedule(event);
    } else {
      this.removeSchedule(event);
    }
  }

  /**
   * Adds a schedule to the availability form.
   * @param event - The event that triggered the addition of a schedule.
   * @param existing - If true, the schedule is an existing one that was already in the availability.
   */
  addSchedule(event, existing = false) {
    this.railsNestedFormOutlet.add(event);

    // Find the new schedule ID input field and update it with the selected schedule ID.
    let newScheduleId = event.target.dataset.scheduleId;
    let newScheduleIdInput = this.scheduleIdInputTargets.find(
      (scheduleIdInput) =>
        scheduleIdInput.dataset.scheduleId === "0" &&
        !this.isMarkedForRemoval(scheduleIdInput),
    );
    if (!newScheduleIdInput) return;

    newScheduleIdInput.value = newScheduleId;
    newScheduleIdInput.dataset.scheduleId = newScheduleId;

    // Update the schedule name in the form.
    let container = newScheduleIdInput.closest(".nested-form-wrapper");
    container.querySelector(
      "[data-schedule-selection-target='scheduleName']",
    ).innerText = event.target.dataset.scheduleName;

    // Update the remove button with the added schedule ID.
    container.querySelector(
      "[data-schedule-selection-target='removeButton']",
    ).dataset.scheduleId = newScheduleId;

    if (existing) {
      container.dataset.newRecord = "false";
      // Add the id input for the existing availability_schedule record after the container.
      let idInput = document.createElement("input");
      // Extract the index for the record
      const index = container.children[0].name.match(/\[(\d+)]/)[1];

      // Set up the id input
      idInput.type = "hidden";
      idInput.id = `availability_availability_schedules_attributes_${index}_id`;
      idInput.name = `availability[availability_schedules_attributes][${index}][id]`;
      idInput.autocomplete = "off";
      idInput.value = event.target.dataset.recordId;
      container.after(idInput);
    }

    this.debouncedCalendarUpdate();
  }

  /**
   * Removes a schedule from the availability form.
   * @param event - The event that triggered the removal of a schedule.
   */
  removeSchedule(event) {
    const targetScheduleId = event.target.dataset.scheduleId;
    const existingInput = this.scheduleIdInputTargets.find(
      (scheduleIdInput) =>
        !this.isMarkedForRemoval(scheduleIdInput) &&
        scheduleIdInput.dataset.scheduleId === targetScheduleId,
    );
    if (!existingInput) return;

    // The outlet only uses the event for the target property to find the wrapper to remove.
    // If the event was triggered by something outside the wrapper, then the target won't be in the desired wrapper.
    // To ensure the target is correct without messing with the event, we can use a new empty event and set the target manually to the wrapped input.
    let hollowEvent = this.makeHollowEvent({ value: existingInput });
    this.railsNestedFormOutlet.remove(hollowEvent);

    // If the schedule was removed via button, uncheck the corresponding checkbox from the schedule list
    const checkbox = this.scheduleToggleTargets.find((toggle) => {
      return toggle.dataset.scheduleId === event.target.dataset.scheduleId;
    });
    if (checkbox) checkbox.checked = false;

    this.debouncedCalendarUpdate();
  }

  makeHollowEvent(attributes) {
    let event = new Event("", undefined);
    Object.defineProperty(event, "target", attributes);
    return event;
  }

  // Checks if a schedule has been marked for removal from the availability
  isMarkedForRemoval(scheduleIdInput) {
    return (
      scheduleIdInput.closest(".nested-form-wrapper").style.display === "none"
    );
  }

  // Updates the calendar with the current schedules.
  updateCalendar() {
    const id = this.calendarOutlet.sourceIdValue;
    this.calendarOutlet.replaceEventSource(id, {
      url: "/calendars",
      method: "GET",
      extraParams: {
        schedule_ids: this.scheduleIdInputTargets
          .filter((input) => !this.isMarkedForRemoval(input))
          .map((input) => input.dataset.scheduleId),
      },
      id: id,
    });
  }

  // This ensures that the checkboxes are in sync with the saved schedules.
  scheduleToggleTargetConnected(element) {
    const scheduleId = element.dataset.scheduleId;
    // A matching non-marked input means the schedule is saved to the availability
    const existingInput = this.scheduleIdInputTargets.find(
      (scheduleIdInput) =>
        !this.isMarkedForRemoval(scheduleIdInput) &&
        scheduleIdInput.dataset.scheduleId === scheduleId,
    );
    element.checked = !!existingInput;
  }

  calendarOutletConnected() {
    this.debouncedCalendarUpdate();
  }

  dialogOutletConnected(dialog) {
    dialog.addSubmitSuccessListener(this.submitSuccessCallback);
  }

  dialogOuterDisconnected(dialog) {
    dialog.removeSubmitSuccessListener(this.submitSuccessCallback);
  }
}
