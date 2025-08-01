import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="availability-selection"
export default class extends Controller {
  static targets = ["availabilitySelectInput"];
  static outlets = ["calendar"];
  static values = { src: String };

  setCalendarAvailability(event) {
    const id = this.calendarOutlet.sourceIdValue;
    this.calendarOutlet.replaceEventSource(id, {
      url: "/calendars",
      method: "GET",
      extraParams: {
        availability_id: this.availabilitySelectInputTarget.value,
      },
      id: id,
    });
  }

  calendarOutletConnected() {
    this.setCalendarAvailability();
  }
}
