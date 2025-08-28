import { Calendar, JsonRequestError } from "@fullcalendar/core";

/**
 * Service class for managing calendar data and functionality.
 */
export default class CalendarService {
  /**
   * Constructs a new CalendarService instance.
   * @param {HTMLElement} calendarElement - The DOM element to render the calendar in.
   * @param {Object} options - Configuration options for the calendar.
   */
  constructor(calendarElement, options) {
    this.fullCalendarObj = this.#createFullCalendar(calendarElement, options);
    this.allCalendars = new Map(); // <calendarId, calendar>
    this.calendarIdsByType = new Map(); // <calendarType, Set<calendarId>>
    this.calendarStates = new Map(); // <calendarId, isActive>
    this.activeCalendarsByType = new Map(); // <calendarType, Set<calendarId>>
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
      eventSourceSuccess: (retrievedCalendars, response) => {
        return this.#processCalendars(retrievedCalendars);
      },
      eventSourceFailure: (errorObj) => {
        if (!(errorObj instanceof JsonRequestError)) return;

        this.#handleError(errorObj);
      },
    };

    return new Calendar(calendarEl, {
      ...options,
      ...optionsOverrides,
    });
  }

  /**
   * Outputs error details as appropriate for the current environment.
   * @param errorObj {JsonRequestError} - The error object containing details about the failure.
   * @param explanation {string} - A message explaining the error context.
   * @param solution {string} - A message suggesting a solution or next steps.
   */
  #handleError(
    errorObj,
    explanation = "There was an error while fetching the calendar! Error: ",
    solution = "\nPlease refresh and try again.",
  ) {
    alert(explanation + errorObj.message + solution);

    if (process.env.NODE_ENV !== "production") {
      console.error(explanation, errorObj);
    }
  }

  /**
   * Processes retrieved calendars and transforms them into FullCalendar events.
   * @param {Array} retrievedCalendars - Array of calendar objects.
   * @returns {Array} An array of FullCalendar event objects.
   */
  #processCalendars(retrievedCalendars) {
    let events = [];
    this.resetData();

    retrievedCalendars.forEach((calendar) => {
      this.#processCalendar(calendar, events);
    });

    return events;
  }

  /**
   * Processes a single calendar and updates the events array.
   * @param {Object} calendar - The calendar object to process.
   * @param {Array} events - The array to store processed events.
   * @private
   */
  #processCalendar(calendar, events) {
    let newCalendar = this.#fillCalendarEvents(calendar);
    if (newCalendar.events.length === 0) return; // Skip empty calendars

    this.allCalendars.set(newCalendar.id, newCalendar);

    if (!this.calendarIdsByType.has(newCalendar.type)) {
      this.calendarIdsByType.set(newCalendar.type, new Set());
    }

    this.calendarIdsByType.get(newCalendar.type).add(newCalendar.id);

    const isActive = this.calendarStates.get(calendar.id) ?? true;
    this.setCalendarActive(newCalendar, isActive, false);

    if (isActive) {
      newCalendar.events.forEach((event) => {
        events.push(event);
      });
    }
  }

  /**
   * Sets the active state of a calendar and updates events if necessary.
   * @param {Object} calendar - The calendar object to update.
   * @param {boolean} active - The new active state.
   * @param {boolean} updateEvents - Whether to update the calendar events.
   */
  setCalendarActive(calendar, active, updateEvents = true) {
    let currentActive = this.activeCalendarsByType.get(calendar.type);
    if (!currentActive) {
      currentActive = new Set();
      this.activeCalendarsByType.set(calendar.type, currentActive);
    }

    if (active) {
      currentActive.add(calendar.id);
    } else {
      currentActive.delete(calendar.id);
    }

    if (this.calendarStates.get(calendar.id) === active) return; // No more work needed if the state is the same

    this.calendarStates.set(calendar.id, active); // Store the new state

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
    if (calendar.schedules.length === 0) {
      calendar.events = [];
      return calendar;
    }

    calendar.events = calendar.schedules.map((schedule) => {
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
    let event = {
      // Each event is derived from a hash that includes IceCube::Schedule data
      start: schedule.start_time.time,
      end: schedule.end_time.time, // End time for the initial event, not the end of recurrence
      allDay: this.#eventIsAllDay(schedule.start_time.time, schedule.duration),
      extendedProps: {
        recordId: schedule.id,
        type: calendar.type,
        selectable: schedule.selectable,
      },
      duration: schedule.duration * 1000, // Convert seconds to milliseconds
    };

    event.title = calendar.title || calendar.name;

    // Set event properties based on calendar type
    switch (calendar.type) {
      case "availability":
        const id = calendar.id.match(/_(\d+)$/)?.[1];
        event.id = `availability_${id}`;
        event.backgroundColor = "green";
        event.extendedProps.route = `/availabilities/${id}`;
        break;
      case "ideal":
        event.id = `ideal`;
        event.backgroundColor = "purple";
        break;
      case "game":
        event.id = `game_${schedule.id}`;
        event.backgroundColor = "blue";
        event.extendedProps.route = `/game_sessions/${schedule.id}`;
        event.extendedProps.group = schedule.group;
        break;
      default: // Single schedule
        event.id = `schedule_${schedule.id}`;
        event.backgroundColor = "orange";
        event.extendedProps.route = `/schedules/${schedule.id}`;
    }

    // Don't want to include RRULE if it's not a recurring event
    if (schedule.cal_rrule && schedule.cal_rrule.includes("RRULE"))
      event.rrule = this.#convertRule(schedule.cal_rrule);

    return event;
  }

  /**
   * Checks if a start time and duration imply an event lasts entire days e.g. from midnight to a following midnight
   * @param startTime - The start time in any format accepted by the Date constructor
   * @param duration - A duration in seconds
   * @returns {boolean} True if event lasts entire days, false otherwise
   */
  #eventIsAllDay(startTime, duration) {
    startTime = new Date(startTime);
    // Check if start is at local midnight and duration is full days
    return (
      startTime.getHours() === 0 &&
      startTime.getMinutes() === 0 &&
      startTime.getSeconds() === 0 &&
      (duration / 60) % 1440 === 0
    );
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
    calendar.events.forEach((currEvent) => {
      if (isActive) {
        this.fullCalendarObj.addEvent(currEvent, "calendarJson");
      } else {
        const existingEvent = this.fullCalendarObj.getEventById(currEvent.id);
        if (existingEvent) {
          existingEvent.remove();
        }
      }
    });
  }

  /**
   * Clears all stored calendar data
   */
  resetData() {
    this.allCalendars.clear();
    this.activeCalendarsByType.clear();
    this.calendarIdsByType.clear();
  }

  refresh() {
    this.fullCalendarObj.refetchEvents();
  }

  replaceEventSource(oldSrcId, newSrc) {
    this.fullCalendarObj.getEventSourceById(oldSrcId).remove();
    this.fullCalendarObj.addEventSource(newSrc);
  }

  /**
   * Returns the current month of the calendar.
   * @param utc {boolean} - If true, returns the month in UTC.
   * @returns {number} The current month of the calendar.
   */
  currentMonth(utc = true) {
    const currentStart = this.fullCalendarObj.view.currentStart;
    return utc ? currentStart.getUTCMonth() : currentStart.getMonth();
  }

  /**
   * Returns the current year of the calendar.
   * @param utc {boolean} - If true, returns the year in UTC.
   * @returns {number} The current year of the calendar.
   */
  currentYear(utc = true) {
    const currentStart = this.fullCalendarObj.view.currentStart;
    return utc ? currentStart.getUTCFullYear() : currentStart.getFullYear();
  }

  /**
   * Returns the current date of the calendar.
   * @param utc {boolean} - If true, returns the date in UTC.
   * @returns {Date} The current date of the calendar.
   */
  currentDate(utc = true) {
    const currentStart = this.fullCalendarObj.view.currentStart;
    return utc
      ? new Date(this.fullCalendarObj.view.currentStart.getTime())
      : currentStart;
  }
}
