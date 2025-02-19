import { Controller } from "@hotwired/stimulus";
import Calendar_controller from "./calendar_controller";

// Connects to data-controller="schedule-selection"
export default class extends Controller {
  static targets = [
    "query",
    "frame",
    "form",
    "spinner",
    "scheduleIdInput",
    "scheduleToggle",
  ];
  static values = {
    src: String,
    frameId: { type: String, default: "modal_frame" },
  };
  static outlets = ["rails-nested-form", "calendar", "dialog"];

  initialize() {
    this.submitSuccessCallback = this.onSubmitSuccess.bind(this);
  }

  onSubmitSuccess() {
    if (this.hasFrameTarget) {
      this.frameTarget.src = this.frameTarget.src;
      const availabilityId = this.frameTarget.dataset.availabilityId;
      if (!availabilityId) {
        return;
      }

      fetch(
        `/availability_schedules.json?availability_id=${this.frameTarget.dataset.availabilityId}`,
      )
        .then((response) => response.json())
        .then((data) => {
          data.forEach((schedule) => {
            // Check for schedules that are not listed in the form and add them
            if (
              this.scheduleIdInputTargets.find(
                (input) =>
                  parseInt(input.dataset.savedScheduleId) === schedule.id,
              )
            )
              return;
            let event = new Event("", undefined);
            Object.defineProperty(event, "target", {
              value: {
                dataset: {
                  scheduleId: schedule.id,
                  scheduleName: schedule.name,
                },
              },
            });
            this.addSchedule(event, true);
          });
        });
    }
  }

  toggleSchedule(event) {
    if (event.target.checked) {
      this.addSchedule(event);
    } else {
      this.removeSchedule(event);
    }
  }

  addSchedule(event, existing = false) {
    this.railsNestedFormOutlet.add(event);

    let newScheduleInput = this.scheduleIdInputTargets.find(
      (scheduleIdInput) =>
        !this.isMarkedForRemoval(scheduleIdInput) &&
        scheduleIdInput.dataset.savedScheduleId === "0",
    );
    if (!newScheduleInput) return;

    newScheduleInput.value = event.target.dataset.scheduleId;
    newScheduleInput.dataset.savedScheduleId = event.target.dataset.scheduleId;
    newScheduleInput.parentElement.querySelector(".schedule-name").innerText =
      event.target.dataset.scheduleName;
    newScheduleInput.parentElement.querySelector(
      ".remove-schedule-button",
    ).dataset.removeId = event.target.dataset.scheduleId;

    if (existing) {
      newScheduleInput.closest(".nested-form-wrapper").dataset.newRecord =
        "false";
    }

    this.updateCalendar();
  }

  removeSchedule(event) {
    const targetScheduleId =
      event.target.dataset.scheduleId || event.target.dataset.removeId;
    const existingInput = this.scheduleIdInputTargets.find(
      (scheduleIdInput) =>
        !this.isMarkedForRemoval(scheduleIdInput) &&
        scheduleIdInput.dataset.savedScheduleId === targetScheduleId,
    );
    if (!existingInput) return;

    // The outlet only uses the event for the target property to find the wrapper to remove.
    // If the event was triggered by something outside the wrapper, then the target won't be in the desired wrapper.
    // To ensure the target is correct without messing with the event, we can use a new empty event and set the target manually to the wrapped input.
    let hollowEvent = new Event("", undefined);
    Object.defineProperty(hollowEvent, "target", { value: existingInput });
    this.railsNestedFormOutlet.remove(hollowEvent);

    // If the schedule was removed via button, uncheck the corresponding checkbox from the schedule list
    const checkbox = this.scheduleToggleTargets.find(
      (toggle) =>
        toggle.dataset.scheduleId === event.originalTarget.dataset.removeId,
    );
    if (checkbox) checkbox.checked = false;

    this.updateCalendar();
  }

  /*
   * Checks if a schedule has been marked for removal from the availability
   */
  isMarkedForRemoval(scheduleIdInput) {
    return (
      scheduleIdInput.closest(".nested-form-wrapper").style.display === "none"
    );
  }

  updateCalendar() {
    const id = this.calendarOutlet.sourceIdValue;
    this.calendarOutlet.replaceEventSource(id, {
      url: "/calendars",
      method: "GET",
      extraParams: {
        schedule_ids: this.scheduleIdInputTargets
          .filter((input) => !this.isMarkedForRemoval(input))
          .map((input) => input.dataset.savedScheduleId),
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
        scheduleIdInput.dataset.savedScheduleId === scheduleId,
    );
    element.checked = !!existingInput;
  }

  calendarOutletConnected() {
    this.updateCalendar();
  }

  dialogOutletConnected(dialog, element) {
    dialog.addSubmitSuccessListener(this.submitSuccessCallback);
    if (element.id === this.frameIdValue) {
      this.modal = dialog;
    }
  }

  dialogOuterDisconnected(dialog, element) {
    dialog.removeSubmitSuccessListener(this.submitSuccessCallback);
    if (element.id === this.frameIdValue) {
      this.modal = null;
    }
  }
}
