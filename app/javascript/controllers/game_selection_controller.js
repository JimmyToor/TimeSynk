import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="game-selection"
export default class extends Controller {
  static targets = [ "gameId", "query", "frame", "form", "spinner"]
  static values = { src: String }

  initialize() {
    document.addEventListener("turbo:before-cache", this.removeSelection.bind(this))
  }

  select(event) {
    this.gameIdTarget.value = event.currentTarget.dataset.gameId

    const newSelected = event.target.closest("button")
    if (this.selectedGame === newSelected) return

    this.removeSelection()
    this.selectedGame = newSelected
    this.submitGameButton = this.selectedGame.parentElement.querySelector(".submit-game-btn")

    this.submitGameButton.classList.remove("hidden")
    this.selectedGame.classList.remove("animate-slide-down")
    void this.selectedGame.offsetWidth // Trigger reflow
    this.selectedGame.classList.add("selected", "animate-slide-down")
  }

  deselect(selected, submitButton) {
    if (selected !== this.selectedGame) submitButton.classList.add("hidden")
    selected.classList.remove("animate-slide-up")
    void this.selectedGame.offsetWidth // Trigger reflow
  }

  removeSelection() {
    if (!this.selectedGame) return;

    this.selectedGame.classList.remove("animate-slide-down", "selected")
    void this.selectedGame.offsetWidth // Trigger reflow
    this.selectedGame.addEventListener("animationend", this.deselect.bind(this, this.selectedGame, this.submitGameButton), { once: true })
    this.selectedGame.classList.add("animate-slide-up")
  }

  submitSelection(event) {
    if (confirm(`Create Game Proposal for ${event.currentTarget.dataset.gameName}?`)) {
      this.submitForm(event)
    }
  }

  submitForm(event) {
    this.gameIdTarget.value = event.currentTarget.dataset.gameId
    this.formTarget.requestSubmit()
  }

  resetSearch(event) {
    event.preventDefault()
    this.queryTarget.value = ""
    this.frameTarget.src = this.srcValue
  }
}
