import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

// Connects to data-controller="flatpickr"
// noinspection JSValidateTypes
export default class extends Controller {
  static targets = ["startDate", "endDate"];
  static values = { timezone: String };
  startDatePicker = null;
  endDatePicker = null;
  done = false;

  disconnect() {
    super.disconnect();
    this.destroyStartDatePicker();
    this.destroyEndDatePicker();
  }

  destroyEndDatePicker() {
    if (this.endDatePicker) {
      this.endDatePicker.destroy();
      this.endDatePicker = null;
    }
  }

  destroyStartDatePicker() {
    if (this.startDatePicker) {
      this.startDatePicker.destroy();
      this.startDatePicker = null;
    }
  }

  initStartDatePicker() {
    if (!this.hasStartDateTarget) return;
    let defaultDate = this.startDateTarget.value || new Date().toISOString();
    this.startDatePicker = this.initDatePicker(
      this.startDateTarget,
      undefined,
      defaultDate,
      (selectedDates, dateStr, instance) => {
        // Ensure the time is rounded up to the nearest 15 minutes
        instance.setDate(this.roundDateMinutesToIncrement(dateStr, 15));

        // Ensure end date is not before start date
        if (!this.endDatePicker) return;
        this.updateMinEndDate();
        if (
          this.endDatePicker.selectedDates[0] < new Date(dateStr) ||
          this.endDatePicker.selectedDates[0] == null
        ) {
          this.endDatePicker.setDate(instance.selectedDates[0]);
        }
      },
      (selectedDates, dateStr, instance) => {
        this.updateMinEndDate();
      },
    );

    document.addEventListener("change", this.startDateChanged);
  }

  initEndDatePicker() {
    if (!this.hasEndDateTarget) return;
    // Priority: 1. Starting end date value 2. Current start date 3. Current date
    let defaultDate =
      this.endDateTarget.value ||
      this.startDatePicker?.selectedDates[0] ||
      new Date().toISOString();
    this.endDatePicker = this.initDatePicker(
      this.endDateTarget,
      this.startDatePicker?.selectedDates[0],
      defaultDate,
    );
  }

  initDatePicker(
    datePickerEl,
    minDate,
    defaultDate = undefined,
    onClose = undefined,
    onChange = undefined,
    increment = 15,
  ) {
    if (defaultDate) {
      defaultDate = this.roundDateMinutesToIncrement(defaultDate, increment);
    }
    return flatpickr(datePickerEl, {
      enableTime: true,
      dateFormat: "Z",
      altInput: true,
      altFormat: "F j, Y h:i K",
      defaultDate: defaultDate,
      minDate: minDate,
      onClose: onClose,
      onChange: onChange,
      allowInput: false,
      altInputClass: "flatpickr-input form-control input",
      static: true,
      minuteIncrement: increment,
    });
  }

  updateMinEndDate() {
    if (!this.hasStartDateTarget || !this.hasEndDateTarget) return;

    this.endDatePicker.set("minDate", this.startDatePicker.selectedDates[0]);
  }

  startDateTargetConnected(element) {
    this.initStartDatePicker();
  }

  endDateTargetConnected(element) {
    this.initEndDatePicker();
  }

  startDateTargetDisconnected(element) {
    this.destroyStartDatePicker();
  }

  endDateTargetDisconnected(element) {
    this.destroyEndDatePicker();
  }

  /**
   * Rounds the given date up to the nearest increment of minutes.
   *
   * @param {string|Date} date - The date to be rounded. Can be a date string or a Date object.
   * @param {number} increment - The minute increment to round to.
   * @returns {Date} - The rounded date.
   */
  roundDateMinutesToIncrement(date, increment) {
    if (increment <= 0) throw new Error("Invalid increment provided.");
    let roundedDate = new Date(date);
    if (isNaN(roundedDate.valueOf())) throw new Error("Invalid date provided.");
    let minutes = roundedDate.getMinutes();

    let minutesOverIncrement = minutes % increment;
    if (minutesOverIncrement === 0) return date;

    let roundedMinutes = minutes + (increment - minutesOverIncrement);
    roundedDate.setMinutes(roundedMinutes, 0, 0);
    return roundedDate;
  }
}
