import {Controller} from "@hotwired/stimulus"
import rrulePlugin from '@fullcalendar/rrule'
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import interaction from '@fullcalendar/interaction';
import CalendarService from "../services/calendar_service";
import ModalService from "../services/modal_service";


/**
 * Main controller class for the calendar functionality.
 * Mainly concerned with UI interactions and rendering.
 * Extends the Stimulus Controller class.
 */
export default class extends Controller {

  static targets = [ "calendar", "toggleDropdown", "toggleDropdownLoading", "availabilityToggles",
    "gameToggles", "scheduleToggles", "availabilityTogglesList", "gameTogglesList", "scheduleTogglesList", "toggleButton" ]

  modalId = 'crud_modal';
  modalFrameId = 'modal_body';
  modalTitleId = 'modal_title';

  connect() {
    this.initCalendar();
    this.initModal();
  }

  /**
   * Initializes the FullCalendar instance with specified options and plugins.
   */
  initCalendar() {
    let calendarEl = this.calendarTarget;
    let url = '/calendars';
    let eventSrc = {
      url: url,
      method: 'GET',
      extraParams: this.extractParams(),
      id: 'calendarJson',
    }

    this.calendarService = new CalendarService(calendarEl, {
      plugins: [rrulePlugin, interaction, dayGridPlugin, timeGridPlugin, listPlugin],
      initialView: 'dayGridMonth',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,listWeek'
      },
      timeZone: 'local',
      loading: this.load.bind(this),
      events: eventSrc,
      eventInteractive: true,
      eventClick: this.eventClick.bind(this),
      eventDidMount: this.eventDidMount.bind(this),
    });
  }

  initModal() {
    this.modalService = new ModalService(this.modalId, this.modalFrameId, this.modalTitleId);
  }

  eventDidMount(info) {
    const el = info.el;
    el.dataset.turboFrame = this.modalFrameId;
    el.dataset.href = info.event.extendedProps.route;
  }

  eventClick(info) {
    this.modalService.setTitle(info.event.title);
    this.modalService.setBody('Loading...');
    this.modalService.openModal();

    Turbo.visit(info.el.dataset.href, { frame: info.el.dataset.turboFrame });
  }

  /**
   * Handles the loading state of the calendar.
   * @param {boolean} isLoading - Indicates if the calendar is currently loading.
   */
  load(isLoading) {
    if (isLoading) {
      this.resetToggleLists();
      // Show the loading indicator
      this.toggleDropdownLoadingTarget.classList.remove('hidden');
    }
    else {
      this.createToggles();
      this.toggleDropdownLoadingTarget.classList.add('hidden');
      this.setToggleVisibility();
    }
  }

  /**
   * Creates toggle buttons for each calendar type and individual calendar.
   */
  createToggles() {
    this.createTypeToggles();
    this.calendarService.allCalendars.forEach(calendar => {
      this.addToggleButton(calendar.type, this.createToggleForCalendar(calendar), false);
      this.updateToggleStates(calendar, this.calendarService.calendarStates.get(calendar.id));
    });
  }

  /**
   * Extracts additional parameters from data attributes and converts them to snake_case.
   * @returns {Object} An object containing the extracted parameters.
   */
  extractParams() {
    let extraParams = {};
    ['scheduleId',
      'groupId',
      'userId',
      'availabilityId',
      'gameSessionId',
      'gameProposalId'
    ].forEach(param => {
      let value = this.data.get(param);
      if (value !== null) extraParams[param.replace(/([A-Z])/g, '_$1').toLowerCase()] = value;
    });
    return extraParams;
  }

  /**
   * Updates the state of toggle buttons for a specific calendar and its type.
   * @param {Object} calendar - The calendar object.
   * @param {boolean} active - The active state of the calendar.
   * @param {boolean} checkTypeToggle - Whether to update the type toggle button.
   */
  updateToggleStates(calendar, active, checkTypeToggle = true) {
    const toggleButton = this.toggleButtonTargets?.find(input => input.dataset.calendarIdParam === calendar.id);
    if (toggleButton) {
      toggleButton.checked = active;
    }

    if (!checkTypeToggle) return;

    // Update the type toggle button if needed
    const typeToggleButton = this.toggleButtonTargets?.find(input => input.dataset.calendarTypeParam === calendar.type);
    if (typeToggleButton) {
      const activeCount = this.calendarService.activeCalendarsByType.get(calendar.type)?.size ?? 0;
      const totalCount = this.calendarService.calendarIdsByType.get(calendar.type)?.size ?? 0;

      // The type toggle button can have three states: checked, unchecked, or indeterminate
      if (activeCount === totalCount) {     // checked
        typeToggleButton.checked = true;
        typeToggleButton.indeterminate = false;
      } else if (activeCount === 0) {       // unchecked
        typeToggleButton.checked = false;
        typeToggleButton.indeterminate = false;
      } else {                              // indeterminate
        // While indeterminate, a click should always set it to unchecked
        typeToggleButton.checked = true;
        typeToggleButton.indeterminate = true;
      }
    }
  }

  /**
   * Creates toggle buttons for each calendar type (availability, game, schedule).
   */
  createTypeToggles() {
    let types =  [["availability", "Availabilities"],
      ["game", "Game Sessions"],
      ["schedule", "Schedules"]];

    types.forEach(([type, typePlural]) => {
      const totalCount = this.calendarService.calendarIdsByType.get(type)?.size ?? 0;

      if (totalCount > 0) {
        const activeCount = this.calendarService.activeCalendarsByType.get(type)?.size ?? 0;
        const indeterminate = activeCount > 0 && activeCount < totalCount;
        const checked = indeterminate ? true : activeCount === totalCount;

        this.addToggleButton(type, this.createToggleForType(type, typePlural, checked, indeterminate), true);
      }
    });
  }

  /**
   * Resets all toggle lists and updates their visibility.
   */
  resetToggleLists() {
    this.availabilityTogglesListTarget.innerHTML = '';
    this.gameTogglesListTarget.innerHTML = '';
    this.scheduleTogglesListTarget.innerHTML = '';
    this.setToggleVisibility();
  }

  /**
   * Toggles the visibility of a specific calendar's events by adding/removing them from the calendar.
   * @param {Event} event - The toggle event.
   */
  toggleCalendar(event) {
    const calendarId = event.params.id;
    const calendar = this.calendarService.allCalendars.get(calendarId);

    this.calendarService.setCalendarActive(calendar, event.target.checked);
    this.updateToggleStates(calendar, event.target.checked);
  }

  /**
   * Toggles all calendars of a specific type.
   * @param {Event} event - The toggle event.
   */
  toggleCalendarType(event) {
    const calendarType = event.params.type;
    const calendarIds = this.calendarService.calendarIdsByType.get(calendarType) || this.findCalendarIdsForType(calendarType);
    const isActive = event.target.indeterminate ? false : event.target.checked;

    event.target.checked = isActive;

    calendarIds?.forEach(id => {
      const calendar = this.calendarService.allCalendars.get(id);
      this.calendarService.setCalendarActive(calendar, isActive);
      this.updateToggleStates(calendar, isActive, false);
    });

    event.target.indeterminate = false;
  }

  /**
   * Finds all calendar IDs for a specific type.
   * @param {string} type - The calendar type.
   * @returns {Array} An array of calendar IDs.
   */
  findCalendarIdsForType(type) {
    let calendarIds = [];
    for (const calendar of this.calendarService.allCalendars.values()) {
      if (calendar.type === type) {
        calendarIds.push(calendar.id);
      }
    }
    return calendarIds;
  }

  /**
   * Adds a toggle button to the appropriate list based on the calendar type.
   * @param {string} calendarType - The type of calendar.
   * @param {DocumentFragment} button - The toggle button element.
   * @param {boolean} before - Whether to insert the button at the beginning of the list.
   */
  addToggleButton(calendarType, button, before = false) {
    let target;

    switch (calendarType) {
      case "availability":
        target = this.availabilityTogglesListTarget;
        break;
      case "game":
        target = this.gameTogglesListTarget;
        break;
      default:
        target = this.scheduleTogglesListTarget;
    }
    if (before) {
      target.insertBefore(button, target.firstChild);
    } else {
      target.appendChild(button);
    }
  }

  /**
   * Creates a toggle button for an individual calendar.
   * @param {Object} calendar - The calendar object.
   * @param {boolean} checked - The initial checked state of the toggle.
   * @returns {DocumentFragment} A document fragment containing the toggle button.
   */
  createToggleForCalendar(calendar, checked = true) {
    const template = document.getElementById('toggle_button_template').content.cloneNode(true);

    const input = template.querySelector('input');
    const label = template.querySelector('label');
    const span = template.querySelector('span');
    const title = calendar.title || calendar.name;

    input.id = `toggle_${calendar.id}`;
    input.checked = checked;

    input.setAttribute('data-calendar-target', `toggleButton`);
    input.setAttribute('data-calendar-id-param', calendar.id);
    input.setAttribute('data-action', "change->calendar#toggleCalendar");

    label.htmlFor = input.id;
    span.textContent = `${title}`;

    return template;
  }

  /**
   * Creates a toggle button for a calendar type.
   * @param {string} calendarType - The type of calendar.
   * @param {string} displayName - The display name for the calendar type.
   * @param {boolean} checked - The initial checked state of the toggle.
   * @param {boolean} indeterminate - The initial indeterminate state of the toggle.
   * @returns {DocumentFragment} A document fragment containing the toggle button.
   */
  createToggleForType(calendarType, displayName, checked = true, indeterminate = false) {
    const template = document.getElementById('toggle_button_template');
    const clone = template.content.cloneNode(true);

    const input = clone.querySelector('input');
    const label = clone.querySelector('label');
    const span = clone.querySelector('span');

    input.id = `toggle_${calendarType.toLowerCase().replace(/\s+/g, '_')}`;
    input.checked = checked;
    input.indeterminate = indeterminate;


    input.setAttribute('data-calendar-target', `toggleButton`);
    input.setAttribute('data-calendar-type-param', calendarType);
    input.setAttribute('data-action', "change->calendar#toggleCalendarType");

    label.htmlFor = input.id
    span.textContent = `All ${displayName}`;
    let numCalendars = this.calendarService.calendarIdsByType.get(calendarType)?.size || 0
    if (numCalendars > 1) {
      span.textContent += ` (${numCalendars})`;
    }

    return clone;
  }

  /**
   * Sets the visibility of toggle sections based on their content.
   */
  setToggleVisibility() {
    const sections = [
      { list: this.availabilityTogglesListTarget, target: this.availabilityTogglesTarget },
      { list: this.gameTogglesListTarget, target: this.gameTogglesTarget },
      { list: this.scheduleTogglesListTarget, target: this.scheduleTogglesTarget }
    ];

    sections.forEach(section => {
      section.target.classList.toggle('hidden', section.list.innerHTML === '');
    });
  }


  //TODO: Use a callback (eventRender?) to resize events in the month view to only render proportionately to the percentage of the day they take up. May need to re-render the calendar after window re-size.
}
