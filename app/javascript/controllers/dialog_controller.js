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
    ignoreSubmitSuccess: {
      type: Boolean,
      default: false,
    },
  };

  initialize() {
    super.initialize();
    this.submitStartHandler = this.handleSubmitStart.bind(this);
    this.submitEndHandler = this.handleSubmitEnd.bind(this);
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
    if (!this.hasDialogTarget) return;

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
      if (!this.ignoreSubmitSuccessValue) {
        this.fireSubmitSuccessEvent(event);
      }
    } else {
      this.fireSubmitFailEvent();
      this.endLoading();
    }
  }

  handleSubmitStart(event) {
    this.startLoading();
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
    if (!this.hasLoadingIndicatorTarget) return;
    this.loadingIndicatorTarget.classList.remove("hidden");
  }

  hideLoadingSpinner() {
    if (!this.hasLoadingIndicatorTarget) return;
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
