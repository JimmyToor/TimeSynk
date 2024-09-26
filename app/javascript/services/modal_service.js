/**
 * Service class for managing modal data and functionality.
 */
export default class ModalService {
  static modalTarget = document.querySelector('dialog')

  constructor(modalId, modalFrameId, modalTitleId) {
    this.modalEl = document.getElementById(modalId);
    this.modalBodyEl = this.modalEl.querySelector(`#${modalFrameId}`);
    this.modalTitleEl = this.modalEl.querySelector(`#${modalTitleId}`);
    this.modalOpenTrigger = new CustomEvent("open-modal");
    this.modalCloseTrigger = new CustomEvent("close-modal");
  }

  setTitle(title) {
    this.modalTitleEl.textContent = title
  }

  setBody(body) {
    this.modalBodyEl.textContent = body
  }

  openModal() {
    window.dispatchEvent(this.modalOpenTrigger);
  }

  closeModal() {
    window.dispatchEvent(this.modalCloseTrigger);
  }
}