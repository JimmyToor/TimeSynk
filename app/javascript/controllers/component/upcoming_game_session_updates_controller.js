import { Controller } from "@hotwired/stimulus";
import consumer from "../../channels/consumer";

// Connects to data-controller="upcoming-game-session-updates"
export default class extends Controller {
  static targets = ["frame", "sessionDate"];
  static values = { max: Number, groupId: Number };

  initialize() {
    this.latestDate = null;
  }

  connect() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "UpcomingGameSessionUpdatesChannel",
        group_id: this.groupIdValue,
      },
      {
        connected: () => {},

        disconnected: () => {},

        received: (data) => {
          if (data) {
            this.updateUpcomingGameSessions(data);
          }
        },
      },
    );
  }

  /**
   * Reloads the upcoming game sessions frame if required.
   * @param data - The data object containing old_date and new_date
   */
  updateUpcomingGameSessions(data) {
    const oldDate = data.old_date;
    const newDate = data.new_date;

    if (this.updateRequired(oldDate, newDate)) {
      this.reloadFrame();
    }
  }

  /**
   * Checks if an update is required to maintain the accuracy of upcoming game sessions.
   * @param oldDate - The old date of the game session
   * @param newDate - The new date of the game session
   * @returns {boolean}
   */
  updateRequired(oldDate, newDate) {
    const currDate = new Date().toISOString();

    if (!this.latestDate) {
      // There are no upcoming sessions yet, so this may be the first one
      return newDate > currDate;
    }

    if (!oldDate) {
      // Assume this is a new game session
      oldDate = newDate;
    }

    if (!newDate) {
      // Assume this is a destroyed game session
      newDate = oldDate;
    }

    const sessionUpcoming = newDate >= currDate;

    if (sessionUpcoming && this.sessionDateTargets.count < this.maxValue) {
      return true;
    }

    return (
      (sessionUpcoming && newDate <= this.latestDate) ||
      (oldDate >= currDate && oldDate <= this.latestDate)
    );
  }

  reloadFrame() {
    this.frameTarget.src = this.frameTarget.dataset.src || this.frameTarget.src;
  }

  sessionDateTargetConnected(element) {
    const sessionDate = new Date(
      element.getAttribute("datetime"),
    ).toISOString();

    if (!this.latestDate || sessionDate > this.latestDate) {
      this.latestDate = sessionDate;
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
