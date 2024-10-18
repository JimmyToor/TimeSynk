import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="mutually-exclusive-select"
export default class extends Controller {
  static targets = [ "collectionSelect", "addButton" ]
  static outlets = [ "rails-nested-form" ]

  connect() {
    this.allValues = Array.from(this.collectionSelectTargets[0].options).map(option => option.value);
    this.cacheSelections();
  }

  initialize() {
    this.cacheSelectionsListener = this.cacheSelections.bind(this);
    this.filterSelectionsListener = this.filterSelections.bind(this);
  }

  filterSelections() {
    const newestValue = this.collectionSelectTargets.slice(-1)[0].value;
    this.collectionSelectTargets.slice(0, -1).forEach(collectionSelect => {
      if (collectionSelect.value === newestValue) {
        let newValue = this.allValues.find(value => !this.selections.has(value));
        this.collectionSelectTargets.slice(-1)[0].value = newValue;
        this.selections.add(newValue);
      }
    });

    this.collectionSelectTargets.forEach(collectionSelect => {
      Array.from(collectionSelect.options).forEach(option => {
        option.disabled = this.selections.has(option.value) && collectionSelect.value !== option.value;
      })
    });

    this.checkAddButtonValidity();
  }

  checkAddButtonValidity() {
    const invalid = this.allValues.length === this.selections.size;
    this.addButtonTarget.disabled = invalid;
    this.addButtonTarget.classList.toggle("hidden", invalid);
  }

  cacheSelections() {
    this.selections = new Set(
      this.collectionSelectTargets
        .map(target => target.value)
        .filter(Boolean)
    );
  }

  addEventListeners(element) {
    element.addEventListener("change", this.cacheSelectionsListener);
    element.addEventListener("change", this.filterSelectionsListener);
    element.addEventListener("rails-nested-form:add", this.filterSelectionsListener)
    element.addEventListener("rails-nested-form:remove", this.cacheSelectionsListener)
    element.addEventListener("rails-nested-form:remove", this.filterSelectionsListener)
  }

  removeEventListeners(element) {
    element.removeEventListener("change", this.cacheSelectionsListener);
    element.removeEventListener("change", this.filterSelectionsListener);
    element.removeEventListener("rails-nested-form:add", this.filterSelectionsListener)
    element.removeEventListener("rails-nested-form:remove", this.cacheSelectionsListener)
    element.removeEventListener("rails-nested-form:remove", this.filterSelectionsListener)
  }

  railsNestedFormOutletConnected() {
    this.removeEventListeners(this.railsNestedFormOutlet.element);
    this.addEventListeners(this.railsNestedFormOutlet.element);
  }
}
