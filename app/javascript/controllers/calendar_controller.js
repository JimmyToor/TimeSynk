import {Controller} from "@hotwired/stimulus"
import {Calendar} from '@fullcalendar/core';
import rrulePlugin from '@fullcalendar/rrule'
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import interaction from '@fullcalendar/interaction';


// Connects to data-controller="calendar"
export default class extends Controller {

  static targets = [ "calendar" ]
  allCalendars = [];
  events = [];

  transformCalendars(retrievedCalendars) {
    console.log("Success! Calendars:", structuredClone(retrievedCalendars));
    this.events = [];
    let calendars = retrievedCalendars.map(calendar => {
      console.log("Calendar:", structuredClone(calendar));
      // Each event is derived from a hash that includes IceCube::Schedule data
      calendar.active = true;
      calendar.events = calendar.schedules.map(schedule => {
        let event = {
          id: schedule.id,
          start: schedule.start_time.time,
          end: schedule.end_time.time,
          allDay: (schedule.duration >= 1440),
        };

        switch (calendar.type) {
          case "availability":
            event.title = calendar.username;
            event.backgroundColor = "green";
            break;
          case "game_session": // Same as game_proposal
          case "game_proposal":
            event.title = schedule.name;
            event.backgroundColor = "blue";
            break;
          default:
            event.title = schedule.name;
            event.backgroundColor = "orange";
        }
        console.log("Type: ", calendar.type, "Event: ", event);

        if (schedule.cal_rrule !== "") {
          let rrule = schedule.cal_rrule;
          if (rrule?.includes("DTEND:")) {
            rrule = rrule.split("DTEND:")[0];
          }
          event.rrule = rrule;
        }

        return event;
      });
      return calendar;
    });

    console.log("Transformed calendars:", calendars);
    this.allCalendars = calendars;
    this.allCalendars.forEach(calendar => {
      if (calendar.active) {
        this.events.push(...calendar.events);
        console.log("Calendar events added:", calendar.events);
      }
    });
    console.log("All events:", this.events);
    return this.events;
  }

  // Multiple (conceptual) calendars, each with their own events. Users can toggle each one.
  // When toggled, a calendar's events are added or removed from the actual rendered calendar's events.
  connect() {
    let calendarEl = this.calendarTarget;
    let url = '/calendars';
    let scheduleId = this.data.get('scheduleId');
    let groupId = this.data.get('groupId');
    let userId = this.data.get('userId');
    let availabilityId = this.data.get('availabilityId');
    let gameSessionId = this.data.get('gameSessionId');
    let gameProposalId = this.data.get('gameProposalId');
    let extraParams = {};
    if (scheduleId != null) extraParams.schedule_id = scheduleId;
    if (groupId !== null) extraParams.group_id = groupId;
    if (userId !== null) extraParams.user_id = userId;
    if (availabilityId !== null) extraParams.availability_id = availabilityId;
    if (gameSessionId !== null) extraParams.game_session_id = gameSessionId;
    if (gameProposalId !== null) extraParams.game_proposal_id = gameProposalId;
    console.log ("Got the following ids: scheduleId: ", scheduleId, "groupId: ", groupId, "userId: ", userId, "availabilityId: ", availabilityId, "gameSessionId: ", gameSessionId, "gameProposalId", gameProposalId);
    let events = [
      {
        title  : 'event1',
        start  : '2024-08-06 10:00:00',
        end   : '2024-08-06 11:00:00',
      },
      {
        title  : 'event2',
        start  : '2024-07-22',
        end    : '2024-07-23'
      },
      {
        title  : 'event3',
        start  : '2024-07-25'
      }
    ];

    let calendar = new Calendar(calendarEl, {
        plugins: [ rrulePlugin, interaction, dayGridPlugin, timeGridPlugin, listPlugin ],
        initialView: 'dayGridMonth',
        headerToolbar: {
            left: 'prev,next today',
            center: 'title',
            right: 'dayGridMonth,timeGridWeek,listWeek'
        },
        timeZone: 'local',
        eventSourceSuccess: this.transformCalendars,
        eventSourceFailure: function (errorObj) {
            alert('there was an error while fetching events! error: ' + errorObj.message);
        },
        events: {
            url: url,
            method: 'GET',
            extraParams: extraParams
        },
    })
    calendar.render();
  }
}
