import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="game-selection"
export default class extends Controller {
  static targets = ["gameId", "form", "spinner"];
  static values = { src: String };

  SELECT_ACTION = "game-selection#select";

  initialize() {
    this.deselectListener = this.deselect.bind(this);
    this.deselectMissingListener = this.deselectMissing.bind(this);
  }

  connect() {
    this.removeEventListeners();
    this.addEventListeners();
    const selected = this.element.querySelector(".selected");
    if (!selected) return;

    this.setGameAndButton(selected);
    this.triggerSelectAnim(selected);
  }

  disconnect() {
    this.removeEventListeners();
    this.selectedGame = null;
    this.gameIdTarget.value = "";
  }

  removeEventListeners() {
    document.removeEventListener("turbo:before-cache", this.deselectListener);
    document.removeEventListener(
      "turbo:before-stream-render",
      this.deselectMissingListener,
    );
  }

  addEventListeners() {
    document.addEventListener("turbo:before-cache", this.deselectListener);
    document.addEventListener(
      "turbo:before-stream-render",
      this.deselectMissingListener,
    );
  }

  select(event) {
    const newSelected = event.target.closest("button");

    if (this.selectedGame) {
      const lastSelectionId = this.selectedGame.dataset.gameId;
      this.deselect();
      if (lastSelectionId === newSelected.dataset.gameId) {
        this.selectedGame = null;
        this.gameIdTarget.value = "";
        return;
      }
    }
    this.setGameAndButton(newSelected);
    this.triggerSelectAnim(newSelected);
  }

  triggerSelectAnim(selected) {
    selected.classList.remove("animate-slide-down");
    this.submitGameButton.classList.remove("hidden");
    void selected.offsetWidth; // Trigger reflow
    selected.classList.add("selected", "animate-slide-down");
  }

  triggerDeselectAnim(selectedGame, submitGameButton) {
    selectedGame.classList.remove("animate-slide-down", "selected");
    submitGameButton.setAttribute("aria-hidden", "true");
    selectedGame.addEventListener(
      "animationend",
      this.deselectCleanup.bind(this, selectedGame),
      { once: true },
    );
    selectedGame.classList.add("animate-slide-up");
  }

  setGameAndButton(newSelected) {
    this.selectedGame = newSelected;
    this.gameIdTarget.value = this.selectedGame.dataset.gameId;
    this.submitGameButton =
      this.selectedGame.parentElement.querySelector(".submit-game-btn");
    this.submitGameButton.setAttribute("aria-hidden", "false");
    this.submitGameButton.disabled = false;
    this.submitGameButton.focus();
    this.selectedGame.setAttribute(
      "aria-label",
      "Deselect " + this.selectedGame.dataset.gameName,
    );
  }

  enableSelectAction(selected) {
    const currAction = selected.getAttribute("data-action") || "";
    if (currAction.includes(this.SELECT_ACTION)) return;
    selected.setAttribute("data-action", currAction + " " + this.SELECT_ACTION);
  }

  disableSelectAction(selected) {
    const currAction = selected.getAttribute("data-action");
    selected.setAttribute(
      "data-action",
      currAction.replace(this.SELECT_ACTION, ""),
    );
  }

  deselectCleanup(selected) {
    selected.classList.remove("animate-slide-up");
    document
      .querySelector("button[data-game-id='" + selected.dataset.gameId + "']")
      .classList.add("hidden");
    this.enableSelectAction(selected);
  }

  deselect() {
    if (!this.selectedGame) return;
    this.submitGameButton.disabled = true;
    this.selectedGame.setAttribute(
      "aria-label",
      "Select " + this.selectedGame.dataset.gameName,
    );
    this.disableSelectAction(this.selectedGame);
    this.triggerDeselectAnim(this.selectedGame, this.submitGameButton);
  }

  deselectMissing(event) {
    if (!this.selectedGame) return;
    if (
      event.detail.newStream.querySelector(
        `button[data-game-id='${this.selectedGame.dataset.gameId}']`,
      ) ||
      document.querySelector(
        `button[data-game-id='${this.selectedGame.dataset.gameId}']`,
      )
    ) {
      return;
    }
    this.selectedGame = null;
  }

  submitSelection(event) {
    if (
      confirm(
        `Create Game Proposal for ${event.currentTarget.dataset.gameName}?`,
      )
    ) {
      this.submitForm(event);
    }
  }

  submitForm(event) {
    this.gameIdTarget.value = event.currentTarget.dataset.gameId;
    this.formTarget.requestSubmit();
  }
}
