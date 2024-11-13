import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="proposal-selection"
export default class extends Controller {
  static targets = ["gameName", "gameArt", "form", "collectionSelect"]

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
        if (this.hasGameNameTarget) {
          this.gameNameTarget.innerHTML = `<h3>${data.name}</h3>`;
        }
        if (this.hasGameArtTarget) {
          this.gameArtTarget.src = data.cover_image_url;
        }
      });

    // Update the form action to use the selected proposal ID
    if (this.hasFormTarget) {
      const url = new URL(this.formTarget.action);
      this.formTarget.action = url.pathname.replace(/game_proposals\/\d+/, `game_proposals/${proposalId}`);
    }
  }

  collectionSelectTargetConnected(element) {
    element.addEventListener("change", this.changeProposal.bind(this));
  }

  collectionSelectTargetDisconnected(element) {
    element.removeEventListener("change", this.changeProposal.bind(this));
  }
}
