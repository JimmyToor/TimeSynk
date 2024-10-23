import Dialog from "@stimulus-components/dialog"

// Connects to data-controller="dialog"
export default class extends Dialog {
  static targets = ["loadingIndicator", "modalBody", "modalTitle"]
  static values = { title: { type: String, default: "Modal" }, frameId: { type: String, default: "modal_frame" } }

  initialize() {
    super.initialize()
    this.formSubmitSuccessEvent = new CustomEvent("modal-form-submit-success", { bubbles: true, detail: { success: true } });
    this.formSubmitFailEvent = new CustomEvent("modal-form-submit-fail", { bubbles: true, detail: { success: false } });
    this.submitStartHandler = this.handleSubmitStart.bind(this);
    this.submitEndHandler = this.handleSubmitEnd.bind(this);
    this.beforeFetchRequestHandler = this.handleBeforeFetchRequest.bind(this);
    this.modalFrameEl = document.getElementById(this.frameIdValue);
  }

  connect() {
    super.connect();
    this.removeTurboListeners(); // Ensure no duplicate listeners
    this.addTurboListeners();
  }

  disconnect() {
    super.disconnect();
    this.removeTurboListeners();
  }

  isInModal(event) {
    return this.modalFrameEl.contains(event.detail.formSubmission.formElement);
  }

  handleBeforeFetchRequest(event) {
    if (event.detail.fetchOptions.headers["X-Sec-Purpose"] === "prefetch") return;
    if (event.target !== this.modalFrameEl) return;

    this.setTitle("Loading...");
    this.hideBody();
    this.showLoadingSpinner();
    this.open();
  }

  handleSubmitEnd(event) {
    if (!this.isInModal(event)) return

    if (event.detail.success) {
      this.fireSubmitSuccessEvent();
      this.close();

    }
    else {
      this.fireSubmitFailEvent();
      this.endLoading(this.titleValue);
    }
  }

  handleSubmitStart(event) {
    if (!this.isInModal(event)) return
    this.loadSubmit();
  }

  fireSubmitSuccessEvent() {
    this.modalFrameEl.dispatchEvent(this.formSubmitSuccessEvent);
  }

  fireSubmitFailEvent() {
    this.modalFrameEl.dispatchEvent(this.formSubmitFailEvent);
  }

  loadSubmit() {
    this.setTitle("Submitting...");
    this.startLoading();
  }

  setTitle(title) {
    this.modalTitleTarget.textContent = title;
  }

  setBody(body) {
    this.modalBodyTarget.textContent = body;
  }

  showBody() {
    this.modalBodyTarget.classList.remove("hidden");
  }

  hideBody() {
    this.modalBodyTarget.classList.add("hidden");
  }

  addSubmitSuccessListener(callback) {
    this.modalFrameEl.removeEventListener("modal-form-submit-success", callback); // Remove duplicate listeners
    this.modalFrameEl.addEventListener("modal-form-submit-success", callback);
  }

  removeSubmitSuccessListener(callback) {
    this.modalFrameEl.removeEventListener("modal-form-submit-success", callback);
  }

  startLoading() {
    this.showLoadingSpinner();
    this.hideBody();
  }

  endLoading(newTitle = null) {
    this.hideLoadingSpinner();
    this.showBody();
    if (newTitle) this.setTitle(newTitle);
  }

  showLoadingSpinner() {
    this.loadingIndicatorTarget.classList.remove("hidden");
  }

  hideLoadingSpinner() {
    this.loadingIndicatorTarget.classList.add("hidden");
  }

  dialogTargetConnected(element) {
    if (this.openValue) {
      this.endLoading()
      this.open();
    }
  }

  addTurboListeners() {
    this.modalFrameEl.addEventListener("turbo:before-fetch-request", this.beforeFetchRequestHandler);
    document.addEventListener("turbo:submit-start", this.submitStartHandler);
    document.addEventListener("turbo:submit-end", this.submitEndHandler);
  }

  removeTurboListeners() {
    this.modalFrameEl.removeEventListener("turbo:before-fetch-request", this.beforeFetchRequestHandler);
    document.removeEventListener("turbo:submit-start", this.submitStartHandler);
    document.removeEventListener("turbo:submit-end", this.submitEndHandler);
  }
}
