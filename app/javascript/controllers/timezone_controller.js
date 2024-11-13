import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone"
export default class extends Controller {
  static targets = ['timezoneSelection']

  initialize() {
    this.browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  }

  timezoneSelectionTargetConnected() {
    this.timezoneSelectionTarget.value = this.browserTimezone;
  }
}
