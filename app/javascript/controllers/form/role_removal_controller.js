import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="role-removal"
export default class extends Controller {
  // Connects to data-action="click->role-removal#toggle"
  toggle(event) {
    const remove_role_field = event.target.nextElementSibling;
    remove_role_field.disabled = !!event.target.checked;
  }
}
