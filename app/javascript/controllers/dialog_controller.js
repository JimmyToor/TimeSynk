import Dialog from "@stimulus-components/dialog";

// Connects to data-controller="dialog"
export default class extends Dialog {
  static targets = [
    "loadingIndicator",
    "modalBody",
    "modalTitle",
    "dialog",
    "status",
  ];
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
    this.backdropCloseListener = this.backdropClose.bind(this); // Bind backdropClose
  }

  connect() {
    super.connect();
    this.removeListeners(); // Ensure no duplicate listeners
    this.addListeners();
  }

  disconnect() {
    super.disconnect();
    this.removeListeners();
  }

  addListeners() {
    this.dialogTarget.addEventListener(
      "turbo:submit-start",
      this.submitStartHandler,
    );
    this.dialogTarget.addEventListener(
      "turbo:submit-end",
      this.submitEndHandler,
    );
    document.addEventListener("fetch-end", this.afterFetchRequestHandler);
    this.dialogTarget.addEventListener("dialog:load", this.loadListener);
    this.element.addEventListener("click", this.backdropCloseListener);
  }

  removeListeners() {
    if (!this.hasDialogTarget) return;

    this.dialogTarget.removeEventListener(
      "turbo:submit-start",
      this.submitStartHandler,
    );
    this.dialogTarget.removeEventListener(
      "turbo:submit-end",
      this.submitEndHandler,
    );
    document.removeEventListener("fetch-end", this.afterFetchRequestHandler);
    this.dialogTarget.removeEventListener("dialog:load", this.loadListener);
    this.element.removeEventListener("click", this.backdropCloseListener);
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
    // Don't load on this dialog if the event is from a separate dialog
    if (event.target.closest("dialog") !== this.dialogTarget) return;
    this.startLoading();
    this.setSavingStatus();
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
    this.setStatus("Loading...");
  }

  endLoading(newTitle = null) {
    this.hideLoadingSpinner();
    this.setStatus("Done");
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

  setStatus(status) {
    if (!this.hasStatusTarget) return;
    this.statusTarget.textContent = status;
  }

  setSavingStatus() {
    this.setStatus("Saving...");
  }
}
