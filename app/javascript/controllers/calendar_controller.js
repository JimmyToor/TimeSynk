import { Controller } from "@hotwired/stimulus"
import Calendar from "@toast-ui/calendar";

// Connects to data-controller="calendar"
export default class extends Controller {
  connect() {
    this.calendar = new Calendar('#calendar', {
      id: "1",
      name: "My Calendar",
      defaultView: 'month',
      color: '#00a9ff',
      bgColor: '#00a9ff',
      dragBgColor: '#00a9ff',
      borderColor: 'red',
      useDetailPopup: false,
      useCreationPopup: false,
      milestone: false
    });
  }
}
