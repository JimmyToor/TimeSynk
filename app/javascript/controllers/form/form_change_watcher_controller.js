import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="form-watcher"
export default class extends Controller {
  static targets = ["submitButton"];

  connect() {
    this.checkForm();
  }

  checkForm() {
    const inputs = this.element.querySelectorAll("input");
    if (
      Array.from(inputs).some(
        (input) => input.dataset.initial && this.checkInputChanged(input),
      )
    ) {
      this.enableSubmitButton();
      return;
    }
    this.disableSubmitButton();
  }

  checkInputChanged(input) {
    // Convert values to strings to handle different types
    const newValue = (
      input.type === "checkbox" ? input.checked : input.value
    ).toString();

    const initialValue = input.dataset.initial.toString();
    return newValue !== initialValue;
  }

  enableSubmitButton() {
    this.submitButtonTarget.disabled = false;
    this.submitButtonTarget.classList.remove("disabled");
  }

  disableSubmitButton() {
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.classList.add("disabled");
  }
}
