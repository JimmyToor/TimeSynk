import {Controller} from "@hotwired/stimulus"
import {Calendar} from '@fullcalendar/core';
import rrulePlugin from '@fullcalendar/rrule'
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import interaction from '@fullcalendar/interaction';


// Connects to data-controller="calendar"
export default class extends Controller {

  static targets = [ "calendar", "toggles" ]
  allCalendars = new Map();
  events = new Map();
  fullCalendarObj = null;

  constructor(context) {
    super(context);
  }

  connect() {
    this.fullCalendarObj = this.createFullCalendar();
    this.fullCalendarObj.render();
  }

  // Multiple toggleable (conceptual) calendars, each with their own events, all displayed via one rendered FullCalendar.
  createFullCalendar() {
    let calendarEl = this.calendarTarget;
    let url = '/calendars';
    let eventSrc = {
      url: url,
      method: 'GET',
      extraParams: this.extractParams(),
      id: 'calendarJson',
    }

    return new Calendar(calendarEl, {
      plugins: [rrulePlugin, interaction, dayGridPlugin, timeGridPlugin, listPlugin],
      initialView: 'dayGridMonth',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,listWeek'
      },
      timeZone: 'local',
      loading: this.load.bind(this),
      eventSourceSuccess: this.transformCalendars.bind(this),
      eventSourceFailure: function (errorObj) {
        alert('there was an error while fetching events! Error: ' + errorObj.message);
      },
      events: eventSrc,
    })
  }

  load(isLoading) {
    this.resetToggles();
    if (isLoading) {
      this.togglesTarget.innerHTML = "Loading...";
    }
    else {
      this.renderToggles()
    }
  }

// Grab extra params to add to the URL and convert them to snake_case for the Rails controller
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

  transformCalendars(retrievedCalendars) {
    let events = [];

    retrievedCalendars.forEach(calendar => {
      this.allCalendars.set(calendar.id, this.fillCalendarEvents(calendar));
    });

    this.allCalendars.forEach(calendar => {
      if (calendar.active) {
        calendar.events.forEach(event => {
          events.push(event);
        });
      }
    });

    return events;
  }

  resetToggles() {
    this.togglesTarget.innerHTML = '';
  }

  fillCalendarEvents(calendar) {
    // Persist existing calendars
    if (this.allCalendars.has(calendar.id)) {
      return this.allCalendars.get(calendar.id);
    }

    // Populate calendar with events
    calendar.active = true;
    calendar.events = calendar.schedules.map(schedule => {
      return this.createEvent(schedule, calendar);
    });

    return calendar;
  }

  createEvent(schedule, calendar) {
    let event = { // Each event is derived from a hash that includes IceCube::Schedule data
      start: schedule.start_time.time,
      end: schedule.end_time.time, // End time for the initial event, not the end of recurrence
      // If the duration is a multiple of 1440 min (24 hours) and starts at midnight (T07:00:00), it lasts for entire days
      allDay: (schedule.duration % 1440 === 0) && schedule.start_time.time.includes("T07:00:00"),
    };

    switch (calendar.type) {
      case "availability":
        event.id = "availability-" + schedule.id;
        event.title = calendar.username;
        event.backgroundColor = "green";
        break;
      case "game_proposal": // Same as game_session
      case "game_session":
        event.id = "gameproposal-" + schedule.id;
        event.title = schedule.name;
        event.backgroundColor = "blue";
        break;
      default: // Single schedule
        event.id = "schedule-" + schedule.id;
        event.title = schedule.name;
        event.backgroundColor = "orange";
    }

    if (schedule.cal_rrule) event.rrule = this.convertRule(schedule.cal_rrule);
    return event;
  }

  convertRule(rrule) {
    // DTEND is not valid for FullCalendar so remove it
    if (rrule?.includes("DTEND:")) {
      rrule = rrule.split("DTEND:")[0];
    }

    return rrule;
  }

  // When toggled, a calendar's events are added or removed from the rendered FullCalendar's events.
  toggleCalendar(calendarId) {
    let calendar = this.allCalendars.get(calendarId);
    if (!calendar) {
      return;
    }

    calendar.active = !calendar.active;

    calendar.events.forEach(event => {
      let existingEvent = this.fullCalendarObj.getEventById(event.id);

      if (!existingEvent) {
        this.fullCalendarObj.addEvent(event, "calendarJson")
      } else {
        existingEvent.remove();
      }
    });
  }

  renderToggles() {
    this.allCalendars.forEach(calendar => {
      let button = this.createToggleButton(calendar.name, [calendar.id]);
      this.addToggleButton(button);
    });

    let availabilityCalendarIds = this.getCalendarIdsForType("availability");
    let gameCalendarIds = this.getCalendarIdsForType("game_session") + this.getCalendarIdsForType("game_proposal");

    if (availabilityCalendarIds.length > 0) {
      let availabilityButton = this.createToggleButton('Availabilities', availabilityCalendarIds);
      this.addToggleButton(availabilityButton);
    }

    if (gameCalendarIds.length > 0) {
      let gameButton = this.createToggleButton('Game Sessions', gameCalendarIds);
      this.addToggleButton(gameButton);
    }
  }

  getCalendarIdsForType(type) {
    let calendarIds = [];
    for (const calendar of this.allCalendars.values()) {
      if (calendar.type === type) {
        calendarIds.push(calendar.id);
      }
    }
    return calendarIds;
  }

  addToggleButton(button) {
    this.togglesTarget.appendChild(button);
    this.togglesTarget.appendChild(document.createElement('br'));
  }

  createToggleButton(calendarType, calendarIds) {
    let button = document.createElement('button');
    button.textContent = `Toggle ${calendarType}`;
    button.addEventListener('click', () => {
      calendarIds.forEach(id => this.toggleCalendar(id));
    });
    return button;
  }

  //TODO: Use a callback (eventRender?) to resize events in the month view to only render proportionately to the percentage of the day they take up. May need to re-render the calendar after window re-size.
}
