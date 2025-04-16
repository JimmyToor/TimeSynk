class CalendarUpdateNotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "calendar_update_notifications_#{params[:stream_id]}"
  end

  def unsubscribed
    stop_stream_from "calendar_update_notifications_#{params[:stream_id]}"
  end
end
