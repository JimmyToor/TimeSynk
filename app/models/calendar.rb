# frozen_string_literal: true

###
# A Calendar is used to contain the schedule information for a specific resource.
class Calendar
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :schedules, :array # Array of hashes with merged Schedule and icecube_schedule values
  attr_accessor :name
  attr_accessor :id
  attr_accessor :title # What should be displayed on the rendered calendar
  attr_accessor :type, :integer
  attr_accessor :user_id # If the calendar is for a user
  attr_accessor :group_id # If the calendar is for a group
  attr_accessor :schedule_id # If the calendar is for a single schedule
  attr_accessor :availability_id # If the calendar is for a single availability
  TYPE_KEYS = [availability: "availability", schedule: "schedule", game: "game"]

  # Can't have enums without ActiveRecord, so we'll do this instead.
  validates :type, inclusion: {in: TYPE_KEYS}

  def attributes
    {schedules: nil, id: nil, title: nil, name: nil, type: nil, user_id: nil, group_id: nil, schedule_id: nil, availability_id: nil}
  end

  def self.broadcast_calendar_update_notification(stream_id, payload)
    ActionCable.server.broadcast("calendar_update_notifications_#{stream_id}", payload)
  end
end
