import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="element-toggle"
export default class extends Controller {
  static targets = ["targetElement"];
  static values = {
    displayStyle: String,
    useArrows: { type: Boolean, default: true },
  };

  triggerToggle(event) {
    const button = event.currentTarget;
    const id = button.dataset.id;
    let target = this.targetElementTargets.find(
      (element) => element.dataset.id === id,
    );

    if (target === null) return;

    if (target.classList.contains("hidden")) {
      target.classList.remove("hidden");
    } else {
      target.classList.add("hidden");
    }

    this.toggleArrows(button, target.classList.contains("hidden"));
  }

  toggleArrows(button, hidden) {
    if (this.useArrowsValue) {
      if (hidden) {
        button.setAttribute("aria-expanded", "false");
        button.innerHTML = "&#9660;"; // Change to down arrow
      } else {
        button.setAttribute("aria-expanded", "true");
        button.innerHTML = "&#9650;"; // Change to up arrow
      }
    }
  }
}
