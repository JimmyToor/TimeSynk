import Dialog from "@stimulus-components/dialog"

// Connects to data-controller="dialog"
export default class extends Dialog {
  static targets = ["loadingIndicator", "modalBody", "modalTitle"]
  static values = { title: { type: String, default: "Modal" }, frameId: { type: String, default: "modal_frame" }, open: {
      type: Boolean,
      default: false,
    } }

  initialize() {
    super.initialize()
    this.submitStartHandler = this.handleSubmitStart.bind(this);
    this.submitEndHandler = this.handleSubmitEnd.bind(this);
    this.beforeFetchRequestHandler = this.handleBeforeFetchRequest.bind(this);
    this.modalFrameEl = document.getElementById(this.frameIdValue);
  }

  connect() {
    super.connect();
    this.modalFrameEl = document.getElementById(this.frameIdValue);
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
    if (event.target !== this.modalFrameEl || !this.hasDialogtarget) return;

    this.setTitle("Loading...");
    this.hideBody();
    this.showLoadingSpinner();
    this.open();
  }

  handleSubmitEnd(event) {
    if (!this.isInModal(event)) return

    if (event.detail.success) {
      this.endLoading();
      this.fireSubmitSuccessEvent(event);
    }
    else {
      this.fireSubmitFailEvent();
      this.endLoading();
    }
  }

  handleSubmitStart(event) {
    if (!this.isInModal(event)) return
    this.loadSubmit();
  }

  fireSubmitSuccessEvent(event) {
    this.modalFrameEl.dispatchEvent(new CustomEvent("modal-form-submit-success", { bubbles: true, detail: { success: true, submitEndEvent: event } }));
  }

  fireSubmitFailEvent(event) {
    this.modalFrameEl.dispatchEvent(new CustomEvent("modal-form-submit-fail", { bubbles: true, detail: { success: false, submitEndEvent: event } }));
  }

  loadSubmit() {
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
  }

  endLoading(newTitle = null) {
    this.hideLoadingSpinner();
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
      this.openValue = false; // Prevent dialog from opening on back/forward navigation
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
