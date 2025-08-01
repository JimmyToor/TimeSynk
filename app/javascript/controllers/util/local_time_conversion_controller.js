import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { format: String };

  connect() {
    this.formatTime();
  }

  formatTime() {
    const datetime = this.element.getAttribute("datetime");
    if (!datetime) return;

    const date = new Date(datetime);
    const formatter = new Intl.DateTimeFormat(
      undefined,
      this.getFormatOptions(),
    );
    this.element.textContent = formatter.format(date);
  }

  getFormatOptions() {
    const format = this.formatValue || "%B %d, %I:%M %p";
    const options = {};

    if (format.includes("%B")) options.month = "long";
    if (format.includes("%d")) options.day = "2-digit";
    if (format.includes("%I")) options.hour = "2-digit";
    if (format.includes("%M")) options.minute = "2-digit";
    if (format.includes("%p")) options.hour12 = true;

    return options;
  }
}
