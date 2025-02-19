import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="element-toggle"
export default class extends Controller {
  static targets = ["targetElement"];
  static values = { displayStyle: String };

  triggerToggle(event) {
    const button = event.target;
    const id = button.dataset.id;
    let target = this.targetElementTargets.find(
      (element) => element.dataset.id === id,
    );

    if (target === null) return;

    if (target.classList.contains("hidden")) {
      target.classList.remove("hidden");
      button.innerHTML = "&#9650;"; // Up arrow
    } else {
      target.classList.add("hidden");
      button.innerHTML = "&#9660;"; // Down arrow
    }
  }
}
