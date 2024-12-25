import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-selection"
export default class extends Controller {
  static targets = [ "gameId", "selectedGame"]
  select(event) {
    event.preventDefault()
    const gameId = event.currentTarget.dataset.gameId
    const gameName = event.currentTarget.dataset.gameName

    this.gameIdTarget.value = gameId
    this.selectedGameTarget.textContent = `Selected Game: ${gameName}`
  }

}
