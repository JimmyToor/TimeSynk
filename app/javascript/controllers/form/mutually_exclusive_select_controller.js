import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="mutually-exclusive-select"
export default class extends Controller {
  static targets = ["collectionSelect", "addButton"];
  static outlets = ["rails-nested-form"];

  initialize() {
    this.cacheSelectionsListener = this.cacheSelections.bind(this);
    this.filterSelectionsListener = this.filterSelections.bind(this);
    this.lateInitListener = this.lateInit.bind(this);
    this.allValues = [];
    this.selections = new Set();
  }

  connect() {
    if (this.hasCollectionSelectTarget) {
      this.initAllValues();
    }
    this.cacheSelections();
    this.checkAddButtonValidity();
  }

  filterSelections() {
    let selectionTargets = this.collectionSelectTargets.filter((target) =>
      target.checkVisibility(),
    );

    if (!this.hasCollectionSelectTarget || !selectionTargets.length) {
      this.checkAddButtonValidity();
      return;
    }

    // If there is only one select, enable all options
    if (selectionTargets.length === 1) {
      Array.from(selectionTargets[0].options).forEach((option) => {
        option.disabled = false;
      });
      this.checkAddButtonValidity();
      return;
    }

    // If the newest (last) select has an already selected value, change it to the first available value
    const newestValue = selectionTargets.slice(-1)[0].value;

    selectionTargets.slice(0, -1).forEach((collectionSelect) => {
      if (collectionSelect.value === newestValue) {
        let newValue = this.allValues.find(
          (value) => !this.selections.has(value),
        );
        selectionTargets.slice(-1)[0].value = newValue;
        this.selections.add(newValue);
      }
    });

    // Disable selected values in other selects
    selectionTargets.forEach((collectionSelect) => {
      Array.from(collectionSelect.options).forEach((option) => {
        option.disabled =
          this.selections.has(option.value) &&
          collectionSelect.value !== option.value;
      });
    });

    this.checkAddButtonValidity();
  }

  checkAddButtonValidity() {
    // Add Button is only valid when we have un-selected values remaining
    let valid = this.hasCollectionSelectTarget
      ? this.allValues.length > this.selections.size
      : true;

    this.addButtonTarget.disabled = !valid;
    this.addButtonTarget.classList.toggle("hidden", !valid);
  }

  cacheSelections() {
    // Selections should be cached before collection selects are added, after they are removed, and after they are changed
    this.selections = new Set();
    let selectionTargets = this.collectionSelectTargets.filter((target) =>
      target.checkVisibility(),
    );

    if (!selectionTargets.length) {
      return;
    }

    this.selections = new Set(
      selectionTargets.map((target) => target.value).filter(Boolean),
    );
  }

  addEventListeners(element) {
    element.addEventListener("change", this.cacheSelectionsListener);
    element.addEventListener("change", this.filterSelectionsListener);
    if (!this.hasCollectionSelectTarget) {
      element.addEventListener("rails-nested-form:add", this.lateInitListener, {
        once: true,
      });
    }
    element.addEventListener(
      "rails-nested-form:add",
      this.cacheSelectionsListener,
    );
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
    element.removeEventListener("rails-nested-form:add", this.lateInitListener);
    element.removeEventListener("change", this.cacheSelectionsListener);
    element.removeEventListener("change", this.filterSelectionsListener);
    element.removeEventListener(
      "rails-nested-form:add",
      this.filterSelectionsListener,
    );
    element.removeEventListener(
      "rails-nested-form:add",
      this.cacheSelectionsListener,
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

  /**
   *  A collectionSelectTarget may not be available by the time connect is called,
   *  so initialize allValues here instead.
   */
  lateInit() {
    if (
      this.collectionSelectTargets?.filter((target) => target.checkVisibility())
        .length !== 1
    )
      return;
    this.initAllValues();
    this.cacheSelections();
  }

  initAllValues() {
    this.allValues = Array.from(this.collectionSelectTargets[0].options).map(
      (option) => option.value,
    );
  }

  railsNestedFormOutletConnected(outlet, element) {
    this.removeEventListeners(this.railsNestedFormOutlet.element);
    this.addEventListeners(this.railsNestedFormOutlet.element);
  }
}
