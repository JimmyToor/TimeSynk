import { Controller } from "@hotwired/stimulus"
import flatpickr from 'flatpickr';

// Connects to data-controller="flatpickr"
// noinspection JSValidateTypes
export default class extends Controller {
  static targets = [ "startDate", "endDate" ]

  connect() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    let startDatePicker = this.startDateTarget;
    let endDatePicker = this.hasEndDateTarget ? this.endDateTarget : null;
    let minStartDate = startDatePicker?.dataset.defaultDate || new Date().toISOString();
    let minEndDate =  endDatePicker?.dataset.defaultDate || minStartDate;

    flatpickr(startDatePicker, {
      enableTime: true,
      dateFormat: "Z",
      altInput: true,
      altFormat: "F j, Y h:i K",
      defaultDate: minStartDate,
      minDate: minStartDate,
    })

    if (endDatePicker) {
      flatpickr(endDatePicker, {
        enableTime: true,
        dateFormat: "Z",
        altInput: true,
        altFormat: "F j, Y h:i K",
        defaultDate: minEndDate,
        minDate: minEndDate,
      })
    }
  }
}
