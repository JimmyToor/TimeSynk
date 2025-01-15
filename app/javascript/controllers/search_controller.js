import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = [ "query", "frame" ]
  static values = { src: String }

  initialize() {
    this.element.addEventListener("turbo:submit-start", this.searchStartListener.bind(this))
    this.element.addEventListener("turbo:submit-end", this.searchEndListener.bind(this))
  }

  resetSearch(event) {
    event.preventDefault()
    this.queryTarget.value = "";
    this.frameTarget.src = this.srcValue;
  }

  setBusy() {
    this.frameTarget.setAttribute("busy", "");
    this.frameTarget.setAttribute("aria-busy", "true");
  }

  setComplete() {
    this.frameTarget.removeAttribute("busy");
    this.frameTarget.removeAttribute("aria-busy");
  }

  searchStartListener(event) {
    if(event.target.id === "search-form") {
      this.setBusy();
    }
  }

  searchEndListener(event) {
    if(event.target.id === "search-form") {
      this.setComplete();
    }
  }
}
