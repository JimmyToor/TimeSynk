import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="proposal-selection"
export default class extends Controller {
  static targets = ["gameName", "gameArt"]

  // Event listener for when a collection is selected
  changeProposal(event) {
    const proposalId = event.target.value;
    // Fetch the game info for the selected proposal
    fetch(`/game_proposals/${proposalId}.json`)
      .then(response => response.json())
      .then(({ game_id }) => {
        return fetch(`/games/${game_id}.json`);
      })
      .then(response => response.json())
      .then(data => {
        this.gameNameTarget.innerHTML = `<h3>${data.name}</h3>`;
        this.gameArtTarget.src = data.cover_image_url;
      });
  }
}
