import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="schedule-selection"
export default class extends Controller {
  static targets = [ "query", "frame", "form", "spinner", "scheduleIdInput", "scheduleToggle"]
  static values = { src: String }
  static outlets = [ "rails-nested-form", "calendar" ]

  toggleSchedule(event) {
    if (event.target.checked) {
      this.addSchedule(event)
    }
    else {
      this.removeSchedule(event)
    }
  }

  addSchedule(event) {
    this.railsNestedFormOutlet.add(event)
    let newScheduleInput = this.scheduleIdInputTargets.find(scheduleIdInput => scheduleIdInput.dataset.savedScheduleId === "0")
    if (!newScheduleInput) return

    newScheduleInput.value = event.target.dataset.scheduleId
    newScheduleInput.dataset.savedScheduleId = event.target.dataset.scheduleId
    newScheduleInput.parentElement.querySelector(".schedule-name").innerText = event.target.dataset.scheduleName
    newScheduleInput.parentElement.querySelector(".remove-schedule-button").dataset.removeId = event.target.dataset.scheduleId

    this.updateCalendar()
  }

  removeSchedule(event) {
    const targetScheduleId = event.target.dataset.scheduleId || event.target.dataset.removeId
    const existingInput = this.scheduleIdInputTargets.find(scheduleId => scheduleId.dataset.savedScheduleId === targetScheduleId);
    if (!existingInput) return

    // Remove this schedule from the list of targets
    delete existingInput.dataset.scheduleSelectionTarget

    // The outlet uses the target property to find the wrapper to remove, so we need to ensure it points to the correct element
    Object.defineProperty(event, 'target', {writable: false, value: existingInput});
    this.railsNestedFormOutlet.remove(event)

    // If the schedule was removed via button, uncheck the corresponding checkbox
    const checkbox = this.scheduleToggleTargets.find(toggle => toggle.dataset.scheduleId === event.explicitOriginalTarget.dataset.removeId);
    if (checkbox) checkbox.checked = false;

    this.updateCalendar()
  }

  updateCalendar() {
    if (this.calendarOutlet) {
      const id = "calendarJson"
      this.calendarOutlet.replaceEventSource(id, {
        url: "/calendars",
        method: 'GET',
        extraParams: { schedule_ids: this.scheduleIdInputTargets.map(input => input.dataset.savedScheduleId) },
        id: id,
      })
    }
  }

  resetSearch(event) {
    event.preventDefault()
    this.queryTarget.value = ""
    this.frameTarget.src = this.srcValue
  }

  // This ensures that the checkboxes are in sync with the saved schedules. Useful for pagination.
  scheduleToggleTargetConnected(element) {
    const scheduleId = element.dataset.scheduleId
    const existingInput = this.scheduleIdInputTargets.find(scheduleIdInput => scheduleIdInput.dataset.savedScheduleId === scheduleId)
    element.checked = !!existingInput
  }

  calendarOutletConnected() {
    this.updateCalendar()
  }
}
