import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["sidebar", "toggleButton", "backdropTemplate"];
  static BACKDROP_CLASS = "sidebar-backdrop";
  initialize() {
    this.visiblityObserver = new IntersectionObserver(
      this._visibilityCallback.bind(this),
    );
    this.sidebarVisible = true;
  }

  toggleDrawer() {
    this.sidebarVisible ? this.hide() : this.show();
  }

  _visibilityCallback(entries) {
    entries.forEach((button) => {
      if (button.isIntersecting) {
        // Intersecting = sidebar is toggleable, default to hidden
        this.hide();
      } else {
        // Non-intersecting = button is hidden, so sidebar is always visible
        this.removeBackdrop();
        this.show(false);
      }
    });
  }

  show(backdrop = true) {
    this.sidebarVisible = true;
    this.sidebarTarget.setAttribute("aria-hidden", "false");
    // Translate the sidebar into view for mobile devices
    this.sidebarTarget.classList.remove("-translate-x-full");
    if (backdrop) this.addBackdrop();
  }

  addBackdrop() {
    if (!this.hasBackdropTemplateTarget) return;

    const backdrop =
      this.backdropTemplateTarget.content.cloneNode(true).children[0];
    backdrop.addEventListener("click", () => this.hide());
    backdrop.classList.add(this.constructor.BACKDROP_CLASS);
    document.body.appendChild(backdrop);
  }

  removeBackdrop() {
    document.querySelector(`.${this.constructor.BACKDROP_CLASS}`)?.remove();
  }

  hide() {
    this.sidebarVisible = false;
    this.sidebarTarget.setAttribute("aria-hidden", "true");
    // Translate the sidebar off-screen for mobile devices
    this.sidebarTarget.classList.add("-translate-x-full");
    if (this.hasBackdropTemplateTarget) {
      this.removeBackdrop();
    }
  }

  toggleButtonTargetConnected(element) {
    if (!element.checkVisibility()) {
      this.show(false);
    }
    this.visiblityObserver.observe(element);
  }

  toggleButtonTargetDisconnected(element) {
    this.visiblityObserver.unobserve(element);
  }
}
