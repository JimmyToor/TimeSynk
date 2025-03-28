import Dialog from "@stimulus-components/dialog";

// Connects to data-controller="dialog"
export default class extends Dialog {
  static targets = ["loadingIndicator", "modalBody", "modalTitle"];
  static values = {
    title: { type: String, default: "Modal" },
    open: {
      type: Boolean,
      default: false,
    },
  };

  initialize() {
    super.initialize();
    this.submitStartHandler = this.handleSubmitStart.bind(this);
    this.submitEndHandler = this.handleSubmitEnd.bind(this);
    this.beforeFetchRequestHandler = this.handleBeforeFetchRequest.bind(this);
    this.afterFetchRequestHandler = this.handleAfterFetchRequest.bind(this);
    this.loadListener = this.startLoading.bind(this);
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

  addTurboListeners() {
    this.dialogTarget.addEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestHandler,
    );
    this.dialogTarget.addEventListener(
      "turbo:submit-start",
      this.submitStartHandler,
    );
    this.dialogTarget.addEventListener(
      "turbo:submit-end",
      this.submitEndHandler,
    );
    this.dialogTarget.addEventListener(
      "fetch-end",
      this.afterFetchRequestHandler,
    );
    this.dialogTarget.addEventListener(
      "turbo:click",
      this.beforeFetchRequestHandler,
    );
    this.dialogTarget.addEventListener("dialog:load", this.loadListener);
  }

  removeTurboListeners() {
    this.dialogTarget.removeEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestHandler,
    );
    this.dialogTarget.removeEventListener(
      "turbo:submit-start",
      this.submitStartHandler,
    );
    this.dialogTarget.removeEventListener(
      "turbo:submit-end",
      this.submitEndHandler,
    );
    this.dialogTarget.removeEventListener(
      "fetch-end",
      this.afterFetchRequestHandler,
    );
    this.dialogTarget.removeEventListener(
      "turbo:click",
      this.beforeFetchRequestHandler,
    );
    this.dialogTarget.removeEventListener("dialog:load", this.loadListener);
  }

  isInModal(event) {
    return this.dialogTarget.contains(event.detail.formSubmission.formElement);
  }

  handleBeforeFetchRequest(event) {
    if (event.detail.fetchOptions?.headers["X-Sec-Purpose"] === "prefetch")
      return;
    if (event.currentTarget !== this.dialogTarget) return;
    this.showLoadingSpinner();
  }

  handleAfterFetchRequest(event) {
    if (event.detail.success) {
      this.endLoading();
    } else {
      //TODO: Handle error
      this.endLoading("Error");
    }
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.endLoading();
      this.fireSubmitSuccessEvent(event);
    } else {
      this.fireSubmitFailEvent();
      this.endLoading();
    }
  }

  handleSubmitStart(event) {
    this.loadSubmit();
  }

  fireSubmitSuccessEvent(event) {
    this.dialogTarget.dispatchEvent(
      new CustomEvent("modal-form-submit-success", {
        bubbles: true,
        detail: { success: true, submitEndEvent: event },
      }),
    );
  }

  fireSubmitFailEvent(event) {
    this.dialogTarget.dispatchEvent(
      new CustomEvent("modal-form-submit-fail", {
        bubbles: true,
        detail: { success: false, submitEndEvent: event },
      }),
    );
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
    this.dialogTarget.removeEventListener(
      "modal-form-submit-success",
      callback,
    ); // Remove duplicate listeners
    this.dialogTarget.addEventListener("modal-form-submit-success", callback);
  }

  removeSubmitSuccessListener(callback) {
    this.dialogTarget.removeEventListener(
      "modal-form-submit-success",
      callback,
    );
  }

  startLoading() {
    this.showLoadingSpinner();
  }

  endLoading(newTitle = null) {
    this.hideLoadingSpinner();
    if (newTitle != null) this.setTitle(newTitle);
  }

  showLoadingSpinner() {
    this.loadingIndicatorTarget.classList.remove("hidden");
  }

  hideLoadingSpinner() {
    this.loadingIndicatorTarget.classList.add("hidden");
  }

  dialogTargetConnected(element) {
    if (this.openValue) {
      this.endLoading();
      this.open();
      this.openValue = false; // Prevent dialog from opening on back/forward navigation
    }
  }
}
