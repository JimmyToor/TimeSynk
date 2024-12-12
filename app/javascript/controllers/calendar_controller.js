import {Controller} from "@hotwired/stimulus"
import rrulePlugin from '@fullcalendar/rrule'
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import interaction from '@fullcalendar/interaction';
import CalendarService from "../services/calendar_service";


/**
 * Main controller class for the calendar functionality.
 * Mainly concerned with UI interactions and rendering.
 * Extends the Stimulus Controller class.
 */
export default class extends Controller {

  static targets = [ "calendar", "toggleDropdown", "toggleDropdownLoading", "toggleDropdownEmpty", "availabilityToggles",
    "gameToggles", "scheduleToggles", "availabilityTogglesList", "gameTogglesList", "scheduleTogglesList", "toggleButton", "calendarLoading"]

  static outlets = ["dialog", "flatpickr"]

  static values = {frameId: { type: String, default: "modal_frame"}, containerId: { type: String, default: "modal_container"}}

  initialize() {
    this.initCalendar();
    this.morphCallback = this.morphRefresh.bind(this)
    this.submitSuccessCallback = this.onSubmitSuccess.bind(this);
    this.debouncedRefreshCallback = this.debounce(this.refreshCallback, 300);
  }

  connect() {
    document.addEventListener("turbo:morph-element", this.morphCallback)
  }

  disconnect() {
    if (this.hasDialogOutlet) {
      this.dialogOutlets.forEach(outlet => {
        this.dialogOuterDisconnected(outlet, outlet.element);
      })
    }
    document.removeEventListener("turbo:morph-element", this.morphCallback)
  }

  morphRefresh(event) {
    // Refresh the calendar if the morphed element has the data-refresh-calendar attribute
    if (event.target.hasAttribute('data-refresh-calendar')) {
      this.debouncedRefreshCallback();
    }
  }

  debounce(func, wait) {
    let timeout;
    return function(...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
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

    let interactive = this.data.has('interactive') ? !this.data.get('interactive') : true;

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
      eventClick: interactive ? this.eventClick.bind(this) : undefined,
      eventDidMount: interactive ? this.eventDidMount.bind(this) : undefined,
      selectable: true,
      selectMirror: true,
      select: interactive ? this.select.bind(this) : undefined,
      unselectCancel: '.dialog'
    });

    this.refreshCallback = this.calendarService.refresh.bind(this.calendarService)
  }

  eventDidMount(info) {
    if (info.event.extendedProps.type !== 'game' && info.event.extendedProps.type !== 'availability') return
    const el = info.el;
    el.dataset.turboFrame = this.frameIdValue;
    el.dataset.href = info.event.extendedProps.route;
    el.classList.add('cursor-pointer');
  }

  select(info) {
    let params = new URLSearchParams();
    ['groupId', 'userId', 'gameProposalId', 'availabilityId'].some(param => {
      const value = this.data.get(param);
      if (value) {
        params.append(param.replace(/([A-Z])/g, '_$1').toLowerCase(), value);
        return true;
      }
    });
    
    Turbo.visit(`/calendars/new?${params.toString()}`, { frame: 'modal_frame' })
    document.addEventListener('turbo:frame-load', (event) => {
      if (event.target.id === 'modal_frame' && this.hasFlatpickrOutlet) {
        this.setModalFormDates(info);
      }
    }, { once: true });
  }

  onSubmitSuccess(event) {
    if (event.detail.submitEndEvent.target.hasAttribute("data-refresh-calendar-on-submit")) {
      this.debouncedRefreshCallback();
    }
  }

  setModalFormDates(info) {
    this.flatpickrOutlets.forEach(outlet => {
      if (outlet.element.closest(`#${this.containerIdValue}`)) {
        if (outlet.hasStartDateTarget) {
          outlet.startDatePicker.setDate(info.start);
        }
        // info's end time is expected to be exclusive so subtract a minute to get the actual end day
        if (outlet.hasEndDateTarget) {
          outlet.updateMinEndDate();
          outlet.endDatePicker.setDate(new Date(info.end.getTime()) - 60000);
        }
      }
    })
  }

  eventClick(info) {
    if (info.event.extendedProps.type !== 'game' && info.event.extendedProps.type !== 'availability') return
    Turbo.visit(info.el.dataset.href, { frame: info.el.dataset.turboFrame });
  }

  /**
   * Handles the loading state of the calendar.
   * @param {boolean} isLoading - Indicates if the calendar is currently loading.
   */
  load(isLoading) {
    if (isLoading) {
      this.resetToggleLists();
      this.calendarLoadingTarget.classList.remove('hidden');
      this.toggleDropdownLoadingTarget.classList.remove('hidden');
    }
    else {
      this.createToggles();
      this.calendarLoadingTarget.classList.add('hidden');

      this.toggleDropdownLoadingTarget.classList.add('hidden');
      this.setToggleVisibility();
    }
  }

  /**
   * Creates toggle buttons for each calendar type and individual calendar.
   */
  createToggles() {
    let empty = true;
    this.createTypeToggles();
    this.calendarService.allCalendars.forEach(calendar => {
      if (calendar.events.length === 0) return;
      empty = false;
      this.addToggleButton(calendar.type, this.createToggleForCalendar(calendar), false);
      this.updateToggleStates(calendar, this.calendarService.calendarStates.get(calendar.id));
    });

    if (empty) {
      this.toggleDropdownEmptyTarget.classList.remove('hidden');
    }
    else {
      this.toggleDropdownEmptyTarget.classList.add('hidden');
    }
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
    this.toggleDropdownEmptyTarget.classList.add('hidden');
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

  dialogOutletConnected(dialog, element) {
    dialog.addSubmitSuccessListener(this.submitSuccessCallback);
    if (element.id === this.frameIdValue) {
      this.modal = dialog;
    }
  }

  dialogOuterDisconnected(dialog, element) {
    dialog.removeSubmitSuccessListener(this.submitSuccessCallback);
    if (element.id === this.frameIdValue) {
      this.modal = null;
    }
  }

  //TODO: Use a callback (eventRender?) to resize events in the month view to only render proportionately to the percentage of the day they take up. May need to re-render the calendar after window re-size.
}
