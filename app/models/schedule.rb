# `start_date` and `end_date` define the valid date range for the schedule.
#
# `end_date` represents the end of recurrence (the end of the final event in the case of "count" recurrence), or the end of the initial event if there is no recurrence.
#
# `duration` is the length of time in seconds that the initial event will last.
class Schedule < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
                  against: [:name, :description],
                  using: { tsearch: { prefix: true } }
  has_many :availability_schedules, dependent: :destroy, inverse_of: :schedule
  has_many :availabilities, through: :availability_schedules
  has_many :user_availabilities, through: :availabilities
  has_many :group_availabilities, through: :availabilities
  has_many :proposal_availabilities, through: :availabilities
  belongs_to :user

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: {scope: :user}
  validates :start_date, timeliness: {on_or_before: :end_date, type: :datetime}, presence: true
  validates :end_date, timeliness: {on_or_after: :start_date, type: :datetime}

  scope :group_availabilities_for_group, ->(group) {
    group_availabilities.where(group_availabilities: {group: group})
  }

  scope :proposal_availabilities_for_proposal, ->(proposal) {
    proposal_availabilities.where(proposal_availabilities: {proposal: proposal})
  }

  store_accessor :schedule_pattern, :rule_type, :interval, :validations

  # Sets the schedule pattern if valid, otherwise sets an empty hash.
  # @param new_schedule_pattern [Hash] the new schedule pattern
  def schedule_pattern=(new_schedule_pattern)
    if RecurringSelect.is_valid_rule?(new_schedule_pattern)
      super(RecurringSelect.dirty_hash_to_rule(new_schedule_pattern).to_hash)
    else
      super({})
    end
  end

  def in_range(icecube_schedule: nil, start_date: nil, end_date: nil)
    return true unless start_date.present? && end_date.present?
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?
    icecube_schedule.occurs_between?(start_date, end_date)
  end

  # Creates an IceCube schedule based on the start date, duration, and schedule pattern.
  # @return [IceCube::Schedule] the created IceCube schedule
  def make_icecube_schedule
    schedule = IceCube::Schedule.new(start_date, {
      duration: duration,
    })
    schedule.add_recurrence_rule(IceCube::Rule.from_hash(schedule_pattern)) unless schedule_pattern.empty?

    schedule
  end

  # Generates data compatible with FullCalendar.
  #
  # Included fields: id, name, duration, user_id, cal_rrule, end_time, extimes, rtimes, start_time.
  # @return [Hash] the calendar data
  def make_calendar_schedule(icecube_schedule = nil)
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?

    rrule = icecube_schedule.to_ical if icecube_schedule.recurrence_rules.present?

    schedule = icecube_schedule.to_hash
    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:user_id] = user_id
    schedule[:cal_rrule] = rrule || ""
    schedule
  end

  # Sets the end date for the schedule if it is not already present.
  # The end date is calculated to be the end of the final occurrence based on the schedule pattern, start date, and duration.
  def set_end_date
    return if end_date.present?

    if schedule_pattern.present?
      self.pattern = schedule_pattern
      self.end_date = if pattern[:until].present?
        pattern[:until][:time]
      elsif duration.present?
        if pattern[:count]
          make_icecube_schedule.last + duration.parts[:minutes]
        else
          start_date + duration.minutes
        end
      end
    elsif duration.present? && start_date.present?
      self.end_date = start_date + duration.minutes
    end
  end

  def self.new_default
    Schedule.new(user_id: Current.user.id, start_date: Time.current.utc, end_date: Time.current.utc + 1.hour, duration: 1.hour)
  end

end
