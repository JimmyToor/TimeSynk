import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="mutually-exclusive-select"
export default class extends Controller {
  static targets = ["collectionSelect", "addButton"];
  static outlets = ["rails-nested-form"];

  connect() {
    this.cacheSelections();
    this.checkAddButtonValidity();
  }

  initialize() {
    this.cacheSelectionsListener = this.cacheSelections.bind(this);
    this.filterSelectionsListener = this.filterSelections.bind(this);
    this.lateInitListener = this.lateInit.bind(this);
    this.allValues = [];
    this.selections = new Set();
  }

  filterSelections() {
    if (!this.hasCollectionSelectTarget || !this.collectionSelectTargets.length)
      return;

    // If there is only one select, enable all options
    if (this.collectionSelectTargets.length === 1) {
      Array.from(this.collectionSelectTargets[0].options).forEach((option) => {
        option.disabled = false;
      });
      this.checkAddButtonValidity();
      return;
    }

    // If the newest (last) select has an already selected value, change it to the first available value
    const newestValue = this.collectionSelectTargets.slice(-1)[0].value;
    this.collectionSelectTargets.slice(0, -1).forEach((collectionSelect) => {
      if (collectionSelect.value === newestValue) {
        let newValue = this.allValues.find(
          (value) => !this.selections.has(value),
        );
        this.collectionSelectTargets.slice(-1)[0].value = newValue;
        this.selections.add(newValue);
      }
    });

    // Disable selected values in other selects
    this.collectionSelectTargets.forEach((collectionSelect) => {
      Array.from(collectionSelect.options).forEach((option) => {
        option.disabled =
          this.selections.has(option.value) &&
          collectionSelect.value !== option.value;
      });
    });

    this.checkAddButtonValidity();
  }

  checkAddButtonValidity() {
    let invalid;
    if (
      !this.hasCollectionSelectTarget ||
      !this.collectionSelectTargets.length
    ) {
      invalid = false;
    } else {
      invalid = this.allValues.length <= this.selections.size;
    }
    this.addButtonTarget.disabled = invalid;
    this.addButtonTarget.classList.toggle("hidden", invalid);
  }

  // Selections should be cached before collection_selects are added, after they are removed, and after they are changed
  cacheSelections() {
    if (!this.collectionSelectTargets.length) return;
    this.selections = new Set(
      this.collectionSelectTargets
        .map((target) => target.value)
        .filter(Boolean),
    );
  }

  addEventListeners(element) {
    element.addEventListener("change", this.cacheSelectionsListener);
    element.addEventListener("change", this.filterSelectionsListener);
    element.addEventListener("rails-nested-form:add", this.lateInitListener);
    element.addEventListener(
      "rails-nested-form:add",
      this.filterSelectionsListener,
    );
    element.addEventListener(
      "rails-nested-form:remove",
      this.cacheSelectionsListener,
    );
    element.addEventListener(
      "rails-nested-form:remove",
      this.filterSelectionsListener,
    );
  }

  removeEventListeners(element) {
    element.removeEventListener("change", this.cacheSelectionsListener);
    element.removeEventListener("change", this.filterSelectionsListener);
    element.removeEventListener("rails-nested-form:add", this.lateInitListener);
    element.removeEventListener(
      "rails-nested-form:add",
      this.filterSelectionsListener,
    );
    element.removeEventListener(
      "rails-nested-form:remove",
      this.cacheSelectionsListener,
    );
    element.removeEventListener(
      "rails-nested-form:remove",
      this.filterSelectionsListener,
    );
  }

  lateInit() {
    if (this.collectionSelectTargets.length !== 1) return;
    this.allValues = Array.from(this.collectionSelectTargets[0].options).map(
      (option) => option.value,
    );
    this.cacheSelections();
  }

  railsNestedFormOutletConnected(outlet, element) {
    this.removeEventListeners(this.railsNestedFormOutlet.element);
    this.addEventListeners(this.railsNestedFormOutlet.element);
  }
}
