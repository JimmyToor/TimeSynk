import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="element-toggle"
export default class extends Controller {
  static targets = [ "targetElement" ]
  static values = { displayStyle: String, elementSelector: String }

  connect() {
    console.log('ElementToggleController connected');
  }

  triggerToggle(event) {
    console.log(event.target)
    const button = event.target;
    const id = button.dataset.id;
    const additionalInfoRow = this.targetElementTargets.find((element) => element.dataset.id === id)
    console.log(additionalInfoRow)

    if (additionalInfoRow === null) return;

    if (additionalInfoRow.style.display === "none" || additionalInfoRow.style.display === '') {
      additionalInfoRow.style.display = this.displayStyleValue;
      button.innerHTML = '&#9650;'; // Up arrow
    } else {
      additionalInfoRow.style.display = "none";
      button.innerHTML = '&#9660;'; // Down arrow
    }
  }
}
