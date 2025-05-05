import Clipboard from "@stimulus-components/clipboard";

// Connects to data-controller="clipboard"
export default class extends Clipboard {
  static targets = ["successContent"];

  copied() {
    // The only difference between this and the original copied method is that
    // it uses successContentTarget instead of successContentValue
    if (!this.hasSuccessContentTarget) {
      super.copied();
      return;
    }

    if (!this.hasButtonTarget) return;

    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.buttonTarget.innerHTML = this.successContentTarget.innerHTML;

    this.timeout = setTimeout(() => {
      this.buttonTarget.innerHTML = this.originalContent;
    }, this.successDurationValue);
  }
}
