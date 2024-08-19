# frozen_string_literal: true

###
# A Calendar is used to contain a collection of IceCube::Schedule objects.
class Calendar
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :schedules, :array # Array of hashes with merged schedule and icecube_schedule values
  attr_accessor :name
  attr_accessor :id
  attr_accessor :username
  attr_accessor :type, :integer
  attr_accessor :user_id # If the calendar is for a user
  attr_accessor :group_id # If the calendar is for a group
  attr_accessor :schedule_id # If the calendar is for a single schedule
  attr_accessor :availability_id # If the calendar is for a single availability
  TYPE_KEYS = [ availability: "availability", schedule: "schedule", game_session: "game_session", game_proposal: "game_proposal" ]

  # Can't have enums without ActiveRecord apparently, so we'll do this instead.
  validates :type, inclusion: { in: TYPE_KEYS }

  def attributes
    { schedules: nil, id: nil, username: nil, name: nil, type: nil, user_id: nil, group_id: nil, schedule_id: nil, availability_id: nil, }
  end

end