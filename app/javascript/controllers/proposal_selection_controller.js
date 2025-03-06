import { Controller } from "@hotwired/stimulus";

const PARAMS =
  "only_art=true&img_size=cover_small&img_classes=border-4 border-primary-900";

// Connects to data-controller="proposal-selection"
export default class extends Controller {
  static targets = [
    "gameName",
    "gameArt",
    "form",
    "collectionSelect",
    "formFrame",
    "submitButton",
  ];

  // Event listener for when a collection is selected
  changeProposal(event) {
    const proposalId = event.target.value;

    this.setBusy();

    this.element.dispatchEvent(
      new CustomEvent("dialog:load", {
        bubbles: true,
        detail: { proposalId },
      }),
    );

    // Fetch the game info for the selected proposal
    fetch(`/game_proposals/${proposalId}.json`)
      .then((response) => response.json())
      .then(({ game_id }) => fetch(`/games/${game_id}.json`))
      .then((response) => response.json())
      .then((data) => {
        this.updateGameInfo(data);

        const url = new URL(this.formTarget.action);

        this.updateForm(url, proposalId);
        this.stopBusy();

        this.element.dispatchEvent(
          new CustomEvent("fetch-end", {
            bubbles: true,
            detail: { success: true },
          }),
        );
      })
      .catch(() => {
        this.stopBusy();

        this.element.dispatchEvent(
          new CustomEvent("fetch-end", {
            bubbles: true,
            detail: { success: false },
          }),
        );
      });
  }

  updateGameInfo(data) {
    if (this.hasGameNameTarget) {
      this.gameNameTarget.innerHTML = `<h3>${data.name}</h3>`;
    }
    if (this.hasGameArtTarget) {
      // Fetch the rendered HTML for the game art
      fetch(`/games/${data.id}?${PARAMS}`)
        .then((response) => response.text())
        .then((html) => {
          this.gameArtTarget.parentElement.outerHTML = html;
        });
    }
  }

  updateForm(url, proposalId) {
    if (this.hasFormTarget) {
      this.formTarget.action = url.pathname.replace(
        /game_proposals\/\d+/,
        `game_proposals/${proposalId}`,
      );
    }

    // Switch to the form for the selected proposal
    if (this.hasFormFrameTarget) {
      this.formFrameTarget.src = url.pathname.replace(
        /game_proposals\/\d+\/game_sessions/,
        `game_proposals/${proposalId}/game_sessions/new`,
      );
    }
  }

  setBusy() {
    this.submitButtonTarget.setAttribute("disabled", true);
    this.formTarget.setAttribute("busy", true);
    this.collectionSelectTarget.setAttribute("disabled", true);
  }

  stopBusy() {
    this.submitButtonTarget.removeAttribute("disabled");
    this.formTarget.removeAttribute("busy");
    this.collectionSelectTarget.removeAttribute("disabled");
  }

  collectionSelectTargetConnected(element) {
    element.addEventListener("change", this.changeProposal.bind(this));
  }

  collectionSelectTargetDisconnected(element) {
    element.removeEventListener("change", this.changeProposal.bind(this));
  }
}
