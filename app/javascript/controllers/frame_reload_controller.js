import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="frame-reload"
export default class extends Controller {
  static targets = ["frame"];
  static values = { src: String, events: String };

  initialize() {
    this.frameReloadListener = this.frameReload.bind(this);
  }

  connect() {
    this.removeListeners();
    this.addListeners();
  }

  disconnect() {
    this.removeListeners();
  }

  removeListeners() {
    if (!this.hasEventsValue) return;
    this.eventsValue.split(" ").forEach((event) => {
      document.removeEventListener(event, this.frameReloadListener);
    });
  }

  addListeners() {
    if (!this.hasEventsValue) return;
    this.eventsValue.split(" ").forEach((event) => {
      document.addEventListener(event, this.frameReloadListener);
    });
  }

  frameReload() {
    if (!this.hasFrameTarget) return;
    this.frameTarget.src = this.srcValue || this.frameTarget.src;
  }
}
