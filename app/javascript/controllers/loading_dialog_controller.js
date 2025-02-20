import { Controller } from "@hotwired/stimulus";
import Dialog from "@stimulus-components/dialog";

export default class extends Dialog {
  static values = { frameId: { type: String, default: "modal_frame" } };

  initialize() {
    super.initialize();
    this.beforeFetchRequestHandler = this.handleBeforeFetchRequest.bind(this);
    this.beforeFetchResponseHandler = this.handleBeforeFetchResponse.bind(this);
  }

  connect() {
    this.frameEl = document.getElementById(this.frameIdValue);
    document.addEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestHandler,
    );
    document.addEventListener(
      "turbo:before-fetch-response",
      this.beforeFetchResponseHandler,
    );
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-fetch-request",
      this.beforeFetchRequestHandler,
    );
    document.removeEventListener(
      "turbo:before-fetch-response",
      this.beforeFetchResponseHandler,
    );
  }

  handleBeforeFetchRequest(event) {
    if (event.detail.fetchOptions.headers["X-Sec-Purpose"] === "prefetch")
      return;

    if (event.target !== this.frameEl || this.frameEl.innerText !== "") return;
    this.open();
  }

  handleBeforeFetchResponse(event) {
    if (event.target !== this.frameEl) return;
    this.close();
  }
}
