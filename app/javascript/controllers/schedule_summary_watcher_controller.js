import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="schedule-summary-watcher"
export default class extends Controller {
  static targets = ["frequencyInput"];

  initialize() {
    this.summaryChangeObserver = new MutationObserver(
      this.updateFrequency.bind(this),
    );
  }

  connect() {
    if (this.findSummary()) {
      this.observeSummaryChanges();
    }
  }

  findSummary() {
    this.summary = this.element.querySelector("#schedule_schedule_pattern");
    return this.summary !== null;
  }

  observeSummaryChanges() {
    this.summaryChangeObserver.observe(this.summary, { attributes: true });
  }

  updateFrequency() {
    if (this.summary != null) {
      this.frequencyInputTarget.value = this.summary.attributes[
        "data-initial-value-str"
      ].value
        .replace(/\*/g, "")
        .trim();
    } else {
      this.frequencyInputTarget.value = "";
    }
  }

  disconnect() {
    if (this.summaryChangeObserver) {
      this.summaryChangeObserver.disconnect();
    }
  }
}
