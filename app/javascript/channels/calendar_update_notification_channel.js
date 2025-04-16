import consumer from "./consumer";

const sub = consumer.subscriptions.create(
  { channel: "CalendarUpdateNotificationChannel", stream_id: "test" },
  {
    connected() {
      // Called when the subscription is ready for use on the server
      console.log("Connected to CalendarUpdateNotificationChannel_test");
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
      console.log("Disconnected from CalendarUpdateNotificationChannel_test");
    },

    received(data) {
      // Called when there's incoming data on the websocket for this channel
      console.log(
        "Received data on CalendarUpdateNotificationChannel_test",
        data,
      );
    },
  },
);
