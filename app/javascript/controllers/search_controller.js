import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search"
export default class extends Controller {
  static targets = [
    "query",
    "frame",
    "form",
    "status",
    "resetButton",
    "tableNavStatus",
  ];
  static values = {
    completeMessage: { type: String, default: "Search Complete." },
  };

  initialize() {
    this.beforeFetchRequestListener = this.beforeFetchRequest.bind(this);
    this.searchBusyListener = this.searchBusyHandler.bind(this);
    this.searchCompleteListener = this.searchCompleteHandler.bind(this);
  }

  connect() {
    this.removeSearchListeners();
    this.addSearchListeners();
  }

  disconnect() {
    this.removeSearchListeners();
  }

  beforeFetchRequest(event) {
    const frameId = this.formTarget.dataset.turboFrame;
    if (frameId) {
      event.detail.fetchOptions.headers["Turbo-Frame"] = frameId;
    }
  }

  searchBusyHandler(event) {
    if (event.target.id !== "search-form") return;
    this.setSearchBusy(event);
    this.setFrameBusy();
  }

  searchCompleteHandler(event) {
    if (event.target.id !== "search-form") return;
    this.setSearchComplete(event);
    this.setFrameComplete();
  }

  addSearchListeners() {
    this.formTarget.addEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestListener,
    );
    this.element.addEventListener(
      "turbo:submit-start",
      this.searchBusyListener,
    );
    this.element.addEventListener(
      "turbo:submit-end",
      this.searchCompleteListener,
    );
  }

  removeSearchListeners() {
    this.formTarget.removeEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestListener,
    );
    this.element.removeEventListener(
      "turbo:submit-start",
      this.searchBusyListener,
    );
    this.element.removeEventListener(
      "turbo:submit-end",
      this.searchCompleteListener,
    );
  }

  resetSearch(event) {
    event.preventDefault();
    if (this.hasQueryTarget) this.queryTarget.value = "";
    this.setResetBusy();
    this.formTarget.requestSubmit();
  }

  setFrameBusy() {
    if (!this.hasFrameTarget) return;
    this.frameTarget.setAttribute("busy", "");
    this.frameTarget.setAttribute("aria-busy", "true");
  }

  setFrameComplete() {
    if (!this.hasFrameTarget) return;
    this.frameTarget.removeAttribute("busy");
    this.frameTarget.removeAttribute("aria-busy");
  }

  setSearchBusy() {
    this.queryTarget.setAttribute("aria-busy", "true");
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = ""; // Clear previous status
    }
  }

  setSearchComplete() {
    this.queryTarget.removeAttribute("aria-busy");
    this.setResetComplete();
    // Allow time for the nav status to update before setting the complete message
    setTimeout(this.setStatusComplete.bind(this), 100);
  }

  setStatusComplete() {
    let status = this.completeMessageValue;
    if (this.hasTableNavStatusTarget) {
      // Include the number of results for screen readers
      status += this.tableNavStatusTarget.textContent;
    }
    this.statusTarget.textContent = status;
  }

  setResetBusy() {
    this.resetButtonTarget.setAttribute("aria-busy", "true");
  }

  setResetComplete() {
    this.resetButtonTarget.removeAttribute("aria-busy");
  }
}
