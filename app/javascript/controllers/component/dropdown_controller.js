import Dropdown from "@stimulus-components/dropdown";

// Connects to data-controller="dropdown"
export default class extends Dropdown {
  te;
  static targets = ["toggleButton"];
  toggle() {
    super.toggle();
    let newExpanded =
      this.toggleButtonTarget.getAttribute("aria-expanded") === "true"
        ? "false"
        : "true";
    this.toggleButtonTarget.setAttribute("aria-expanded", newExpanded);
  }

  forceHide() {
    this.leave();
  }
}
