import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["query", "frame"];
  static values = { src: String };

  initialize() {
    this.searchBusyListener = this.setSearchBusy.bind(this);
    this.searchCompleteListener = this.setSearchComplete.bind(this);
  }

  connect() {
    this.removeSearchListeners();
    this.addSearchListeners();
  }

  disconnect() {
    this.removeSearchListeners();
  }

  removeSearchListeners() {
    this.element.removeEventListener(
      "turbo:submit-start",
      this.searchBusyListener,
    );
    this.element.removeEventListener(
      "turbo:submit-end",
      this.searchCompleteListener,
    );
  }

  addSearchListeners() {
    this.element.addEventListener(
      "turbo:submit-start",
      this.searchBusyListener,
    );
    this.element.addEventListener(
      "turbo:submit-end",
      this.searchCompleteListener,
    );
  }

  resetSearch(event) {
    event.preventDefault();
    if (this.hasQueryTarget) this.queryTarget.value = "";
    if (this.hasFrameTarget) this.frameTarget.src = this.srcValue;
  }

  setBusy() {
    if (!this.hasFrameTarget) return;
    this.frameTarget.setAttribute("busy", "");
    this.frameTarget.setAttribute("aria-busy", "true");
  }

  setComplete() {
    if (!this.hasFrameTarget) return;
    this.frameTarget.removeAttribute("busy");
    this.frameTarget.removeAttribute("aria-busy");
  }

  setSearchBusy(event) {
    if (event.target.id === "search-form") {
      this.setBusy();
    }
  }

  setSearchComplete(event) {
    if (event.target.id === "search-form") {
      this.setComplete();
    }
  }
}
