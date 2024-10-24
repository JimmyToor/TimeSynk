import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone"
export default class extends Controller {
  static targets = ['timezoneSelection']

  initialize() {
    this.browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  }

  timezoneSelectionTargetConnected() {
    const options = Array.from(this.timezoneSelectionTarget.options);
    const optionValues = options.map(option => option.value);

    if (optionValues.includes(this.browserTimezone)) {
      this.timezoneSelectionTarget.value = this.browserTimezone;
    }
  }
}
