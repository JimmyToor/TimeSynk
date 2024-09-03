import { Controller } from "@hotwired/stimulus"
import flatpickr from 'flatpickr';

// Connects to data-controller="flatpickr"
// noinspection JSValidateTypes
export default class extends Controller {
  static targets = [ "startDate", "endDate" ]
  startDatePicker = null;
  endDatePicker = null;

  connect() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;

    let startDatePickerEl = this.startDateTarget;
    let endDatePickerEl = this.hasEndDateTarget ? this.endDateTarget : null;

    this.initStartDatePicker(startDatePickerEl);
    this.initEndDatePicker(endDatePickerEl);
  }

  initStartDatePicker(startDatePickerEl) {
    if (startDatePickerEl == null) return;

    let startDefaultDate = startDatePickerEl.dataset.defaultDate || new Date().toISOString();
    let startMinDate = startDatePickerEl.dataset.minDate || undefined;

    this.startDatePicker = this.initDatePicker(startDatePickerEl, startDefaultDate, startMinDate,
      (selectedDates, dateStr, instance) => {
        if (this.endDatePicker == null) return;

        // Ensure end date is not before start date
        if (this.endDatePicker.selectedDates[0] < new Date(dateStr)) {
          this.endDatePicker.setDate(instance.selectedDates[0]);
        }
        this.endDatePicker.set('minDate', dateStr);
      });
  }

  initEndDatePicker(endDatePickerEl) {
    if (endDatePickerEl == null) {
      // End date target might not be present right away, so observe for it to be added to the DOM
      this.observeForEndDateTarget();
      return;
    }

    let endDefaultDate = endDatePickerEl?.dataset.defaultDate || this.startDatePicker.selectedDates[0] || new Date().toISOString();
    let endMinDate = endDatePickerEl?.dataset.minDate || this.startDatePicker.selectedDates[0] || undefined;

    this.endDatePicker = this.initDatePicker(endDatePickerEl, endDefaultDate, endMinDate);
  }

  initDatePicker(datePickerEl, defaultDate, minDate, onClose = undefined) {
    let options = {
      enableTime: true,
      dateFormat: "Z",
      altInput: true,
      altFormat: "F j, Y h:i K",
      defaultDate: defaultDate,
      minDate: minDate,
      onClose: onClose,
    }

    return flatpickr(datePickerEl, options);
  }

  observeForEndDateTarget() {
    const observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        if (mutation.type === 'childList') {
          mutation.addedNodes.forEach(node => {
            if (node.nodeType === Node.ELEMENT_NODE && this.checkForEndDate(node))
              observer.disconnect();
          });
        }
      });
    });

    observer.observe(this.element, {childList: true, subtree: true})
  }

  checkForEndDate(node) {
    if (node.matches('[data-flatpickr-target="endDate"]')) {
      this.initEndDatePicker(node);
      return true;
    }

    let endDateElement = node.querySelector('[data-flatpickr-target="endDate"]');
    if (endDateElement) {
      this.initEndDatePicker(endDateElement);
      return true;
    }

    return false;
  }
}

