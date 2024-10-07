import { Controller } from "@hotwired/stimulus"
import flatpickr from 'flatpickr';

// Connects to data-controller="flatpickr"
// noinspection JSValidateTypes
export default class extends Controller {
  static targets = [ "startDate", "endDate" ]
  startDatePicker = null;
  endDatePicker = null;
  done = false;

  connect() {
    console.log("Flatpickr controller connected");
    this.initializePickers();
  }

  disconnect() {
    this.destroyPickers();
  }

  initializePickers() {
    this.initStartDatePicker();
    this.initEndDatePicker();
  }

  destroyPickers() {
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

    this.startDatePicker = this.initDatePicker(this.startDateTarget, undefined, undefined,
      (selectedDates, dateStr, instance) => {
        if (this.endDatePicker) { // Ensure end date is not before start date
          if (this.endDatePicker.selectedDates[0] < new Date(dateStr)) {
            this.endDatePicker.setDate(instance.selectedDates[0]);
          }
          this.endDatePicker.set('minDate', dateStr);
        }
      });
  }

  initEndDatePicker() {
    if (!this.hasEndDateTarget) return;
    // Priority: 1. Value from endDateTarget, 2. Value from startDatePicker, 3. Current date
    let defaultDate = this.endDateTarget.value || this.startDatePicker?.selectedDates[0] || new Date().toISOString();

    this.endDatePicker = this.initDatePicker(this.endDateTarget, this.startDatePicker?.selectedDates[0], defaultDate);
  }

  initDatePicker(datePickerEl, minDate, defaultDate = undefined, onClose = undefined) {
    return flatpickr(datePickerEl, {
      enableTime: true,
      dateFormat: "Z",
      altInput: true,
      altFormat: "F j, Y h:i K",
      defaultDate: defaultDate || datePickerEl.value,
      minDate: minDate,
      onClose: onClose,
      allowInput: false,
      altInputClass: "flatpickr-input form-control input",
      static:true,
    });
  }

  startDateTargetConnected(element) {
    this.initStartDatePicker();
  }

  endDateTargetConnected(element) {
    this.initEndDatePicker();
  }

  startDateTargetDisconnected(element) {
    this.destroyStartDatePicker()
  }

  endDateTargetDisconnected(element) {
    this.destroyEndDatePicker()
  }
}

