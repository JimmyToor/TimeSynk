import { Controller } from "@hotwired/stimulus";
import rrulePlugin from "@fullcalendar/rrule";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";
import interaction from "@fullcalendar/interaction";
import CalendarService from "../services/calendar_service";
import consumer from "../channels/consumer";
import Utility from "../../../lib/util/utility";
/**
 * Main controller class for the calendar functionality.
 * Mainly concerned with UI interactions and rendering.
 * Extends the Stimulus Controller class.
 */
export default class extends Controller {
  static targets = [
    "calendar",
    "toggleDropdown",
    "toggleDropdownLoading",
    "toggleDropdownEmpty",
    "availabilityToggles",
    "gameToggles",
    "scheduleToggles",
    "availabilityTogglesList",
    "gameTogglesList",
    "scheduleTogglesList",
    "toggleButton",
    "calendarLoading",
    "toggleTemplate",
    "updateNotification",
  ];

  static outlets = ["dialog", "flatpickr"];

  static values = {
    frameId: { type: String, default: "modal_frame" },
    containerId: { type: String, default: "modal_container" },
    sourceId: { type: String, default: "calendarJson" },
    interactive: { type: Boolean, default: true },
    streamId: { type: String, default: null },
    disambiguate: { type: Boolean, default: false },
  };

  initialize() {
    this.initCalendar();
    this.eventRefreshCallback = this.eventRefresh.bind(this);
    this.submitSuccessCallback = this.onSubmitSuccess.bind(this);
    this.debouncedRefreshCallback = Utility.debounceFn(
      this.refreshCallback,
      300,
    );
    this.eventFrameLoadCallback = null;
    this.dateFrameLoadCallback = null;
    this.frameMissingHandler = this.#handleFrameMissing.bind(this);
  }

  connect() {
    this.removeRefreshListeners();
    this.addRefreshListeners();
    this.subscribeToUpdateNotifier();
  }

  disconnect() {
    if (this.hasDialogOutlet) {
      this.dialogOutlets.forEach((outlet) => {
        this.dialogOuterDisconnected(outlet, outlet.element);
      });
    }
    if (this.calendarUpdateNotificationChannel) {
      this.calendarUpdateNotificationChannel.unsubscribe();
      this.subscription = null;
    }
    this.removeRefreshListeners();
  }

  /**
   * Initializes the FullCalendar instance with specified options and plugins.
   */
  initCalendar() {
    let calendarEl = this.calendarTarget;
    let url = "/calendars";
    let eventSrc = {
      url: url,
      method: "GET",
      extraParams: this.extractParams(),
      id: this.sourceIdValue,
    };

    let interactive = this.interactiveValue;

    this.calendarService = new CalendarService(calendarEl, {
      plugins: [
        rrulePlugin,
        interaction,
        dayGridPlugin,
        timeGridPlugin,
        listPlugin,
      ],
      initialView: "dayGridMonth",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,listWeek",
      },
      timeZone: "local",
      loading: this.load.bind(this),
      events: eventSrc,
      eventInteractive: interactive,
      eventClick: interactive ? this.eventClick.bind(this) : undefined,
      eventDidMount: interactive ? this.eventDidMount.bind(this) : undefined,
      selectable: false,
      selectMirror: true,
      dateClick: interactive ? this.dateClick.bind(this) : undefined,
      unselectCancel: ".dialog",
      height: "auto",
      displayEventEnd: true,
      eventDisplay: "block",
      datesSet: this.hideNotifier.bind(this),
    });

    this.refreshCallback = this.refresh.bind(this);
  }

  removeRefreshListeners() {
    document.removeEventListener(
      "turbo:before-stream-render",
      this.eventRefreshCallback,
    );

    document.removeEventListener("turbo:submit-end", this.eventRefreshCallback);

    document.removeEventListener("turbo:frame-error", this.frameMissingHandler);

    if (this.eventFrameLoadCallback) {
      document.removeEventListener(
        "turbo:frame-load",
        this.eventFrameLoadCallback,
      );
    }
    if (this.dateFrameLoadCallback) {
      document.removeEventListener(
        "turbo:frame-load",
        this.dateFrameLoadCallback,
      );
    }
  }

  addRefreshListeners() {
    document.addEventListener(
      "turbo:before-stream-render",
      this.eventRefreshCallback,
    );
    document.addEventListener("turbo:frame-missing", this.frameMissingHandler);

    document.addEventListener("turbo:submit-end", this.eventRefreshCallback);
  }

  eventRefresh(event) {
    if (
      this.eventRequestsRefresh(event) &&
      !event.detail.fetchResponse.response.redirected
    ) {
      this.debouncedRefreshCallback();
    }
  }

  eventRequestsRefresh(event) {
    return (
      event.target.hasAttribute("data-refresh-calendar-on-submit") ||
      event.detail?.formSubmission?.formElement?.hasAttribute(
        "data-refresh-calendar-on-submit",
      )
    );
  }

  manualRefresh() {
    this.debouncedRefreshCallback();
  }

  subscribeToUpdateNotifier() {
    // Ensure we don't create duplicate subscriptions
    if (this.calendarUpdateNotificationChannel) {
      this.calendarUpdateNotificationChannel.unsubscribe();
    }
    const streamId = this.streamIdValue;
    if (!streamId) {
      return;
    }

    this.calendarUpdateNotificationChannel = consumer.subscriptions.create(
      {
        channel: "CalendarUpdateNotificationChannel",
        stream_id: streamId,
      },
      {
        connected: () => {},

        disconnected: () => {},

        received: (data) => this.toggleUpdateNotifier(data.dates),
      },
    );
  }

  showNotifier() {
    if (!this.updateNotificationTarget) return;
    this.updateNotificationTarget.classList.remove("hidden");
  }

  hideNotifier() {
    if (!this.updateNotificationTarget) return;
    this.updateNotificationTarget.classList.add("hidden");
  }

  replaceEventSource(oldSrcId, newSrc) {
    this.calendarService.replaceEventSource(oldSrcId, newSrc);
  }

  eventDidMount(info) {
    const { type, selectable, route } = info.event.extendedProps;
    if ((type !== "game" && type !== "availability") || !selectable) return;

    const el = info.el;
    el.dataset.turboFrame = this.frameIdValue;
    el.dataset.href = route;
    el.dataset.turboStream = "true";
    el.classList.add("cursor-pointer");
    el.setAttribute("role", "button");
    el.setAttribute("tabindex", "0");
    el.setAttribute("aria-haspopup", "true");

    const startTime = info.event.start.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    });
    const startDate = info.event.start.toLocaleDateString();

    let endTime = info.event.end.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    });
    let endDate = info.event.end.toLocaleDateString(undefined, {
      year: "numeric",
      month: "long",
      day: "numeric",
    });

    el.setAttribute(
      "aria-label",
      `View ${info.event.title} - Starts at ${startTime} on ${startDate} - Ends at ${endTime} on ${endDate}`,
    );
    if (this.disambiguateValue && info.event.extendedProps.group) {
      const eventFrame = info.el.querySelector(".fc-event-main-frame");

      if (!eventFrame && process.env.NODE_ENV !== "production") {
        console.warn(
          "Event frame not found for disambiguation. Ensure the calendar is set up correctly.",
        );
        return;
      }

      this.disambiguateEvent(eventFrame, info.event.extendedProps.group);
    }
  }

  disambiguateEvent(containerEl, textContent) {
    const groupNode = document.createElement("div");
    groupNode.classList.add("fc-event-group");
    groupNode.textContent = textContent;
    containerEl.appendChild(groupNode);
  }

  onSubmitSuccess(event) {
    if (
      event.detail.submitEndEvent.target.hasAttribute(
        "data-refresh-calendar-on-submit",
      ) ||
      event.detail.submitEndEvent.target.querySelector(
        "[data-refresh-calendar-on-submit]",
      )
    ) {
      this.debouncedRefreshCallback();
    }
  }

  setModalFormDate(info) {
    if (!info.date) return false;

    this.flatpickrOutlets.forEach((outlet) => {
      if (outlet.element.closest(`#${this.containerIdValue}`)) {
        if (outlet.hasStartDateTarget) {
          outlet.startDatePicker.setDate(info.date);
          return true;
        }
      }
    });
    return false;
  }

  eventClick(info) {
    info.jsEvent.preventDefault();
    if (
      (info.event.extendedProps.type !== "game" &&
        info.event.extendedProps.type !== "availability") ||
      !info.event.extendedProps.selectable
    )
      return;

    this.displayLoading();

    const frameId = info.el.dataset.turboFrame;

    Turbo.visit(info.el.dataset.href, {
      frame: frameId,
    });

    this.addEventFrameLoadCallback(frameId);
  }

  /**
   * Handles missing turbo frame errors.
   * @param {Event} event - The event object.
   */
  #handleFrameMissing(event) {
    if (
      event.target.id !== this.frameIdValue ||
      !event.detail ||
      !event.detail.response
    ) {
      return;
    }

    event.preventDefault();

    const explanation = "Oops! That game session may have been deleted.";
    alert(explanation);
    if (process.env.NODE_ENV !== "production") {
      console.error(
        explanation,
        "Response from server: ",
        event.detail.response,
      );
    }
    this.hideLoading();
    this.manualRefresh();
  }

  dateClick(info) {
    this.displayLoading();

    let params = new URLSearchParams();
    ["groupId", "userId", "gameProposalId", "availabilityId"].some((param) => {
      const value = this.data.get(param);
      if (value) {
        // Convert camelCase param key to snake_case and append to params
        params.append(param.replace(/([A-Z])/g, "_$1").toLowerCase(), value);
        return true;
      }
    });

    params.append("date", info.dateStr);

    Turbo.visit(`/calendars/new?${params.toString()}`, {
      frame: this.frameIdValue,
    });

    this.addDateFrameLoadCallback(info);
  }

  /**
   * Handles the loading state of the calendar.
   * @param {boolean} isLoading - Indicates if the calendar is currently loading.
   */
  load(isLoading) {
    if (isLoading) {
      this.resetToggleLists();
      this.displayLoading();
    } else {
      this.createToggles();
      this.hideLoading();
      this.setToggleVisibility();
    }
  }

  displayLoading() {
    this.calendarLoadingTarget.classList.remove("hidden");
    this.toggleDropdownLoadingTarget.classList.remove("hidden");
  }

  hideLoading() {
    this.calendarLoadingTarget.classList.add("hidden");
    this.toggleDropdownLoadingTarget.classList.add("hidden");
  }

  /**
   * Creates toggle buttons for each calendar type and individual calendar.
   */
  createToggles() {
    if (!this.hasToggleTemplateTarget) return;
    let empty = true;
    this.createTypeToggles();
    this.calendarService.allCalendars.forEach((calendar) => {
      if (calendar.events.length === 0) return;
      empty = false;
      this.addToggleButton(
        calendar.type,
        this.createToggleForCalendar(calendar),
      );
      this.updateToggleStates(
        calendar,
        this.calendarService.calendarStates.get(calendar.id),
      );
    });

    if (empty) {
      this.toggleDropdownEmptyTarget.classList.remove("hidden");
    } else {
      this.toggleDropdownEmptyTarget.classList.add("hidden");
    }
  }

  /**
   * Extracts additional parameters from data attributes and converts them to snake_case.
   * @returns {Object} An object containing the extracted parameters.
   */
  extractParams() {
    let extraParams = {};
    [
      "scheduleId",
      "groupId",
      "userId",
      "availabilityId",
      "gameSessionId",
      "gameProposalId",
      "excludeAvailabilities",
    ].forEach((param) => {
      const value = this.data.get(param);
      if (value !== null) {
        // Convert camelCase param keys to snake_case
        extraParams[param.replace(/([A-Z])/g, "_$1").toLowerCase()] = value;
      }
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
    const toggleButton = this.toggleButtonTargets?.find(
      (input) => input.dataset.calendarIdParam === calendar.id,
    );
    if (toggleButton) {
      toggleButton.checked = active;
    }

    if (!checkTypeToggle) return;

    // Update the type toggle button if needed
    const typeToggleButton = this.toggleButtonTargets?.find(
      (input) => input.dataset.calendarTypeParam === calendar.type,
    );
    if (typeToggleButton) {
      const activeCount =
        this.calendarService.activeCalendarsByType.get(calendar.type)?.size ??
        0;
      const totalCount =
        this.calendarService.calendarIdsByType.get(calendar.type)?.size ?? 0;

      // The type toggle button can have three states: checked, unchecked, or indeterminate
      if (activeCount === totalCount) {
        // checked
        typeToggleButton.checked = true;
        typeToggleButton.indeterminate = false;
      } else if (activeCount === 0) {
        // unchecked
        typeToggleButton.checked = false;
        typeToggleButton.indeterminate = false;
      } else {
        // indeterminate
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
    let types = [
      ["availability", "Availabilities"],
      ["game", "Game Sessions"],
      ["schedule", "Schedules"],
    ];

    types.forEach(([type, typePlural]) => {
      const totalCount =
        this.calendarService.calendarIdsByType.get(type)?.size ?? 0;

      if (totalCount > 0) {
        const activeCount =
          this.calendarService.activeCalendarsByType.get(type)?.size ?? 0;
        const indeterminate = activeCount > 0 && activeCount < totalCount;
        const checked = indeterminate ? true : activeCount === totalCount;

        this.addToggleButton(
          type,
          this.createToggleForType(type, typePlural, checked, indeterminate),
          true,
        );
      }
    });
  }

  /**
   * Resets all toggle lists and updates their visibility.
   */
  resetToggleLists() {
    this.availabilityTogglesListTarget.innerHTML = "";
    this.gameTogglesListTarget.innerHTML = "";
    this.scheduleTogglesListTarget.innerHTML = "";
    this.toggleDropdownEmptyTarget.classList.add("hidden");
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
    const calendarIds =
      this.calendarService.calendarIdsByType.get(calendarType) ||
      this.findCalendarIdsForType(calendarType);
    const isActive = event.target.indeterminate ? false : event.target.checked;

    event.target.checked = isActive;

    calendarIds?.forEach((id) => {
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
    const template = this.toggleTemplateTarget.content.cloneNode(true);

    const input = template.querySelector("input");
    const label = template.querySelector("label");
    const span = template.querySelector("span");
    const title = calendar.title || calendar.name;

    input.id = `toggle_${calendar.id}`;
    input.checked = checked;

    input.setAttribute("data-calendar-target", `toggleButton`);
    input.setAttribute("data-calendar-id-param", calendar.id);
    input.setAttribute("data-action", "change->calendar#toggleCalendar");

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
  createToggleForType(
    calendarType,
    displayName,
    checked = true,
    indeterminate = false,
  ) {
    const template = this.toggleTemplateTarget;
    const clone = template.content.cloneNode(true);

    const input = clone.querySelector("input");
    const label = clone.querySelector("label");
    const span = clone.querySelector("span");

    input.id = `toggle_${calendarType.toLowerCase().replace(/\s+/g, "_")}`;
    input.checked = checked;
    input.indeterminate = indeterminate;

    input.setAttribute("data-calendar-target", `toggleButton`);
    input.setAttribute("data-calendar-type-param", calendarType);
    input.setAttribute("data-action", "change->calendar#toggleCalendarType");

    label.htmlFor = input.id;
    span.textContent = `All ${displayName}`;

    return clone;
  }

  /**
   * Sets the visibility of toggle sections based on their content.
   */
  setToggleVisibility() {
    const sections = [
      {
        list: this.availabilityTogglesListTarget,
        target: this.availabilityTogglesTarget,
      },
      {
        list: this.gameTogglesListTarget,
        target: this.gameTogglesTarget,
      },
      {
        list: this.scheduleTogglesListTarget,
        target: this.scheduleTogglesTarget,
      },
    ];

    sections.forEach((section) => {
      section.target.classList.toggle("hidden", section.list.innerHTML === "");
    });
  }

  /**
   * Adds a callback for when a turbo frame is loaded after an event click. Prevents duplicate listeners.
   * @param frameId - The ID of the turbo frame to watch for.
   */
  addEventFrameLoadCallback(frameId) {
    if (this.eventFrameLoadCallback) {
      document.removeEventListener(
        "turbo:frame-load",
        this.eventFrameLoadCallback,
      );
    }

    this.eventFrameLoadCallback = this.onEventFrameLoad.bind(this, frameId);

    document.addEventListener("turbo:frame-load", this.eventFrameLoadCallback);
  }

  /**
   * Adds a callback for when a turbo frame is loaded after a date click. Prevents duplicate listeners.
   * @param info - The date information. Used to set the date in the modal form.
   */
  addDateFrameLoadCallback(info) {
    if (this.dateFrameLoadCallback) {
      document.removeEventListener(
        "turbo:frame-load",
        this.dateFrameLoadCallback,
      );
    }

    this.dateFrameLoadCallback = this.onDateFrameLoad.bind(this, info);

    document.addEventListener("turbo:frame-load", this.dateFrameLoadCallback);
  }

  /**
   * Handles the cleanup after loading the turbo frame from an event click.
   * @param frameId - The ID of the turbo frame to watch for.
   * @param event - The event object.
   */
  onEventFrameLoad(frameId, event) {
    if (event.target.id === frameId) {
      this.hideLoading();

      document.removeEventListener(
        "turbo:frame-load",
        this.eventFrameLoadCallback,
      );
      this.eventFrameLoadCallback = null;
    }
  }

  /**
   * Handles the cleanup after loading the turbo frame from a date click.
   * @param info - The date information. Used to set the date in the modal form.
   * @param event - The event object.
   */
  onDateFrameLoad(info, event) {
    if (
      event.target.id === this.frameIdValue ||
      this.isInFrame(event.target.id)
    ) {
      // Don't remove the listener until the date is set
      if (this.setModalFormDate(info)) {
        document.removeEventListener(
          "turbo:frame-load",
          this.dateFrameLoadCallback,
        );
        this.dateFrameLoadCallback = null;
      }
      this.hideLoading();
    }
  }

  isInFrame(targetId) {
    return !!(
      this.frameIdValue &&
      targetId &&
      document
        .querySelector(`#${this.frameIdValue}`)
        .querySelector(`#${targetId}`)
    );
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

  refresh() {
    this.calendarService.refresh();
    this.hideNotifier();
  }

  // Displays the update notifier if the current month matches any of the provided dates, indicating that the calendar should be updated.
  // @param {Array} dates - An array of dates to check against the current month. Null or empty array means always update.
  toggleUpdateNotifier(dates) {
    // Treat no date as always update
    if (!dates?.length) {
      this.showNotifier();
      return;
    }
    dates.some((date) => {
      if (date == null) return;
      let affectedDate = new Date(date);
      if (affectedDate.getMonth() === this.calendarService.currentMonth()) {
        this.showNotifier();
        return true;
      }
    });
  }
}
