import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="reload-on-restore"
// Reloads the turbo frame on a restoration visit to prevent stale content
export default class extends Controller {
  static values = { src: { type: String } };

  connect() {
    document.addEventListener("turbo:load", this.reloadOnRestore);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.reloadOnRestore);
  }

  reloadOnRestore = (event) => {
    // A visitStart without a requestStart indicates a restoration visit
    if (!event.detail.timing?.requestStart && event.detail.timing?.visitStart) {
      this.element.src =
        this.srcValue || this.element.dataset.src || this.element.src;
    }
  };
}
