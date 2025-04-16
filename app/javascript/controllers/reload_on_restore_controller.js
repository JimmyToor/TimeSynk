import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="reload-on-restore"
// Reloads the turbo frame on a restoration visit to prevent stale content
export default class extends Controller {
  static values = { src: { type: String, default: "/" } };
  connect() {
    if (!document.documentElement.hasAttribute("data-turbo-visit-direction"))
      return;

    const direction = document.documentElement.getAttribute(
      "data-turbo-visit-direction",
    );
    if (direction === "back" || direction === "forward") {
      this.element.src = this.srcValue
        ? this.srcValue
        : this.element.dataset.src;
    }
  }
}
