import { Controller } from "@hotwired/stimulus";

const PARAMS =
  "only_art=true&img_size=cover_small&img_classes=border-4 border-primary-900";

// Connects to data-controller="proposal-selection"
export default class extends Controller {
  static targets = [
    "gameName",
    "gameArt",
    "groupName",
    "form",
    "collectionSelect",
    "formFrame",
    "submitButton",
    "dateInput",
  ];

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
      .then((proposalData) => {
        this.updateGroupName(proposalData.group_name);
        return proposalData;
      })
      .then((data) => fetch(`/games/${data.game_id}.json`))
      .then((response) => response.json())
      .then((gameData) => {
        this.updateGameInfo(gameData);

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
      .catch((error) => {
        this.#handleError(error);

        this.stopBusy();

        this.element.dispatchEvent(
          new CustomEvent("fetch-end", {
            bubbles: true,
            detail: { success: false },
          }),
        );
      });
  }

  /**
   * Outputs error details as appropriate for the current environment.
   * @param errorObj {JsonRequestError} - The error object containing details about the failure.
   * @param explanation {string} - A message explaining the error context.
   * @param solution {string} - A message suggesting a solution or next steps.
   */
  #handleError(
    errorObj,
    explanation = "There was an error while switching games! Error: ",
    solution = "\nPlease refresh and try again.",
  ) {
    alert(explanation + errorObj.message + solution);

    if (process.env.NODE_ENV !== "production") {
      console.error(explanation, errorObj);
    }
  }

  updateGameInfo(data) {
    if (this.hasGameNameTarget) {
      this.gameNameTarget.innerHTML = `<h3>${data.name}</h3>`;
    }
    if (this.hasGameArtTarget) {
      // Fetch the HTML for the game art
      fetch(`/games/${data.id}?${PARAMS}`)
        .then((response) => response.text())
        .then((html) => {
          this.gameArtTarget.parentElement.outerHTML = html;
        });
    }
  }

  updateGroupName(groupName) {
    if (this.hasGroupNameTarget) {
      this.groupNameTarget.innerHTML = `${groupName}`;
    }
  }

  updateForm(url, proposalId) {
    if (!this.hasFormTarget) return;
    this.formTarget.action = url.pathname.replace(
      /game_proposals\/\d+/,
      `game_proposals/${proposalId}`,
    );
  }

  setBusy() {
    if (!this.hasSubmitButtonTarget) return;
    this.submitButtonTarget.setAttribute("disabled", true);
    this.formTarget.setAttribute("busy", true);
    this.collectionSelectTarget.setAttribute("disabled", true);
  }

  stopBusy() {
    if (!this.hasSubmitButtonTarget) return;
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
