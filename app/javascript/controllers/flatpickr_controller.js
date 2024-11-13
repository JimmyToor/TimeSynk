import { Controller } from "@hotwired/stimulus"
import flatpickr from 'flatpickr';

// Connects to data-controller="flatpickr"
// noinspection JSValidateTypes
export default class extends Controller {
  static targets = [ "startDate", "endDate" ]
  static values = { timezone: String }
  startDatePicker = null;
  endDatePicker = null;
  done = false;

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
    this.startDatePicker = this.initDatePicker(this.startDateTarget, undefined, defaultDate,
      (selectedDates, dateStr, instance) => {
        if (this.endDatePicker) { // Ensure end date is not before start date
          this.updateMinEndDate();
          if (this.endDatePicker.selectedDates[0] < new Date(dateStr) || this.endDatePicker.selectedDates[0] == null) {
            this.endDatePicker.setDate(instance.selectedDates[0]);
          }
        }
      },
      (selectedDates, dateStr, instance) => {
        this.updateMinEndDate();
      }
    );

    document.addEventListener('change', this.startDateChanged);
  }

  initEndDatePicker() {
    if (!this.hasEndDateTarget) return;
    // Priority: 1. Starting end date value 2. Current start date 3. Current date
    let defaultDate = this.endDateTarget.value || this.startDatePicker?.selectedDates[0] || new Date().toISOString();
    this.endDatePicker = this.initDatePicker(this.endDateTarget, this.startDatePicker?.selectedDates[0], defaultDate);
  }

  initDatePicker(datePickerEl, minDate, defaultDate = undefined, onClose = undefined, onChange = undefined) {
    return flatpickr(datePickerEl, {
      enableTime: true,
      dateFormat: "Z",
      altInput: true,
      altFormat: "F j, Y h:i K",
      defaultDate: defaultDate || datePickerEl.value,
      minDate: minDate,
      onClose: onClose,
      onChange: onChange,
      allowInput: false,
      altInputClass: "flatpickr-input form-control input",
      static:true,
      minuteIncrement: 1
    });
  }

  updateMinEndDate() {
    if (!this.hasStartDateTarget || !this.hasEndDateTarget) return;

    this.endDatePicker.set('minDate', this.startDatePicker.selectedDates[0]);
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

