import { Controller } from "@hotwired/stimulus";
import Pagy from "../../../vendor/assets/javascripts/pagy.mjs";
export default class extends Controller {
  connect() {
    Pagy.init(this.element);
  }
}
