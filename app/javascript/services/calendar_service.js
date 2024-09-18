import {Calendar} from '@fullcalendar/core';

/**
 * Service class for managing calendar data and functionality.
 */
export default class CalendarService {

  /**
   * Constructs a new CalendarService instance.
   * @param {HTMLElement} calendarElement - The DOM element to render the calendar in.
   * @param {Object} options - Configuration options for the calendar.
   */
  constructor(calendarElement, options ) {
    this.fullCalendarObj = this.#createFullCalendar(calendarElement, options);
    this.allCalendars = new Map();
    this.calendarIdsByType = new Map();
    this.calendarStates = new Map();
    this.activeCalendarsByType = new Map();
    this.fullCalendarObj.render();
  }

  /**
   * Creates a FullCalendar instance with custom options.
   * @param {HTMLElement} calendarEl - The DOM element to render the calendar in.
   * @param {Object} optionsOverrides - Additional options to override defaults.
   * @returns {Calendar} A FullCalendar instance.
   */
  #createFullCalendar(calendarEl, optionsOverrides = {}) {
    const options = {
      eventSourceSuccess: this.#processCalendars.bind(this),
      eventSourceFailure: function (errorObj) {
        alert('there was an error while fetching events! Error: ' + errorObj.message);
      },
    };

    return new Calendar(calendarEl, {
      ...options,
      ...optionsOverrides
    });
  }

  /**
   * Processes retrieved calendars and transforms them into FullCalendar events.
   * @param {Array} retrievedCalendars - Array of calendar objects.
   * @returns {Array} An array of FullCalendar event objects.
   */
  #processCalendars(retrievedCalendars) {
    let events = [];
    this.resetData();

    retrievedCalendars.forEach(calendar => {
      let newCalendar = this.#fillCalendarEvents(calendar);
      this.allCalendars.set(newCalendar.id, newCalendar);

      if (!this.calendarIdsByType.has(newCalendar.type)) {
        this.calendarIdsByType.set(newCalendar.type, new Set());
      }
      this.calendarIdsByType.get(newCalendar.type).add(newCalendar.id);

      const isActive = this.calendarStates.get(calendar.id) ?? true;
      this.setCalendarActive(newCalendar, isActive, false);

      if (isActive) {
        newCalendar.events.forEach(event => {
          events.push(event);
        });
      }
    });

    return events;
  }

  /**
   * Sets the active state of a calendar and updates events if necessary.
   * @param {Object} calendar - The calendar object to update.
   * @param {boolean} active - The new active state.
   * @param {boolean} updateEvents - Whether to update the calendar events.
   */
  setCalendarActive(calendar, active, updateEvents = true) {
    // Push the id to the activeCalendarsByType map if active, otherwise remove it
    let currentActive = this.activeCalendarsByType.get(calendar.type);
    if (!currentActive) {
      currentActive = new Set();
      this.activeCalendarsByType.set(calendar.type, currentActive);
    }

    if (active) {
      currentActive.add(calendar.id);
    }
    else {
      currentActive.delete(calendar.id);
    }

    if (this.calendarStates.get(calendar.id) === active) return; // No more work needed if the state is the same

    this.calendarStates.set(calendar.id, active); // Store the state

    if (updateEvents) {
      this.#updateCalendarEvents(calendar);
    }
  }

  /**
   * Populates a calendar with events based on its schedules.
   * @param {Object} calendar - The calendar object to populate.
   * @returns {Object} The populated calendar object.
   */
  #fillCalendarEvents(calendar) {
    // Populate calendar with events
    calendar.events = calendar.schedules.map(schedule => {
      return this.#createEvent(schedule, calendar);
    });

    return calendar;
  }

  /**
   * Creates a FullCalendar event object from a schedule and calendar.
   * @param {Object} schedule - The schedule object.
   * @param {Object} calendar - The calendar object.
   * @returns {Object} A FullCalendar event object.
   */
  #createEvent(schedule, calendar) {
    let event = { // Each event is derived from a hash that includes IceCube::Schedule data
      start: schedule.start_time.time,
      end: schedule.end_time.time, // End time for the initial event, not the end of recurrence
      // If the duration is a multiple of 1440 min (24 hours) and starts at midnight (T07:00:00), it lasts for entire days
      allDay: (schedule.duration % 1440 === 0) && schedule.start_time.time.includes("T07:00:00"),
    };

    event.title = calendar.title || calendar.name;

    // Set event properties based on calendar type
    switch (calendar.type) {
      case "availability":
        event.id = `availability-${schedule.id}`;
        event.backgroundColor = "green";
        break;
      case "game":
        event.id = `game-${schedule.id}`;
        event.backgroundColor = "blue";
        break;
      default: // Single schedule
        event.id = `schedule-${schedule.id}`;
        event.backgroundColor = "orange";
    }

    if (schedule.cal_rrule) event.rrule = this.#convertRule(schedule.cal_rrule);
    return event;
  }

  /**
   * Converts an ICal RRULE to a FullCalendar compatible format.
   * @param {string} rrule - The ICal RRULE string.
   * @returns {string} A FullCalendar compatible RRULE string.
   */
  #convertRule(rrule) {
    // Remove DTEND as it's not valid for FullCalendar
    if (rrule?.includes("DTEND:")) {
      rrule = rrule.split("DTEND:")[0];
    }

    return rrule;
  }

  /**
   * Updates the events of a specific calendar in the FullCalendar instance.
   * @param {Object} calendar - The calendar object to update.
   */
  #updateCalendarEvents(calendar) {
    const isActive = this.calendarStates.get(calendar.id);
    calendar.events.forEach(currEvent => {
      const existingEvent = this.fullCalendarObj.getEventById(currEvent.id);
      if (isActive && !existingEvent) {
        this.fullCalendarObj.addEvent(currEvent, "calendarJson");
      } else if (!isActive && existingEvent) {
        existingEvent.remove();
      }
    });
  }

  /**
   * Resets all internal data structures.
   */
  resetData() {
    this.allCalendars.clear();
    this.activeCalendarsByType.clear();
    this.calendarIdsByType.clear();
  }
}