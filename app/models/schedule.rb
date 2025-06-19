# `duration` is the length of time in seconds that the initial event will last.
# `end_time` represents the end of the initial event i.e. start + duration
class Schedule < ApplicationRecord
  require "rounding"

  include PgSearch::Model
  pg_search_scope :search,
    against: [:name, :description],
    using: {tsearch: {prefix: true}}

  has_many :availability_schedules, dependent: :destroy, inverse_of: :schedule
  has_many :availabilities, through: :availability_schedules
  has_many :user_availabilities, through: :availabilities
  has_many :group_availabilities, through: :availabilities
  has_many :proposal_availabilities, through: :availabilities
  belongs_to :user

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.squish }

  validates :name, presence: true, uniqueness: {scope: :user}, length: {maximum: 300}
  validates :description, allow_blank: true, length: {maximum: 300}
  validates :start_time, timeliness: {on_or_before: :end_time, type: :datetime}, presence: true
  validates :end_time, timeliness: {on_or_after: :start_time, type: :datetime}

  after_commit :touch_availabilities

  scope :group_availabilities_for_group, ->(group) {
    group_availabilities.where(group_availabilities: {group: group})
  }

  scope :proposal_availabilities_for_proposal, ->(proposal) {
    proposal_availabilities.where(proposal_availabilities: {proposal: proposal})
  }

  store_accessor :schedule_pattern, :rule_type, :interval, :validations

  DEFAULT_PARAMS = {
    name: "New Schedule",
    description: "",
    start_time: Time.current.utc.ceil_to(15.minutes),
    end_time: Time.current.utc.ceil_to(15.minutes) + 1.hour,
    duration: 1.hour
  }

  ScheduleStart = Struct.new(:date, :schedule)
  ScheduleEnd = Struct.new(:date, :schedule)
  ScheduleInterval = Struct.new(:start, :end, :schedule)

  # Sets the schedule pattern if valid, otherwise sets an empty hash.
  # @param new_schedule_pattern [Hash] the new schedule pattern
  def schedule_pattern=(new_schedule_pattern)
    if RecurringSelect.is_valid_rule?(new_schedule_pattern)
      super(RecurringSelect.dirty_hash_to_rule(new_schedule_pattern).to_hash)
    else
      super({})
    end
  end

  # Checks if the schedule occurs within the given time range.
  # @param icecube_schedule [IceCube::Schedule] the IceCube schedule. Will be created if not passed.
  # @param start_time [Time] the start time of the range. Defaults to the current time.
  # @param end_time [Time] the end time of the range. Defaults to one month from nowi.
  # @return [Boolean] true if the schedule occurs within the range, false otherwise
  def in_range(icecube_schedule: make_icecube_schedule, start_time: Time.current, end_time: Time.current + 1.month)
    icecube_schedule.occurs_between?(start_time, end_time)
  end

  # Creates an IceCube schedule based on the start date, duration, and schedule pattern.
  # @return [IceCube::Schedule] the created IceCube schedule
  def make_icecube_schedule
    schedule = IceCube::Schedule.new(start_time, {
      duration: duration
    })
    schedule.add_recurrence_rule(IceCube::Rule.from_hash(schedule_pattern)) unless schedule_pattern.empty?
    schedule
  end

  # Generates data compatible with FullCalendar.
  #
  # Included fields: id, name, duration, user_id, cal_rrule, end_time, extimes, rtimes, start_time.
  # @param icecube_schedule [IceCube::Schedule, nil] the IceCube schedule
  # @param selectable [Boolean] whether the schedule is selectable in FullCalendar
  # @return [Hash] the calendar data
  def make_calendar_schedule(icecube_schedule = nil, selectable: true)
    icecube_schedule = make_icecube_schedule if icecube_schedule.nil?

    rrule = icecube_schedule.to_ical if icecube_schedule

    schedule = icecube_schedule.to_hash
    schedule[:id] = id
    schedule[:name] = name
    schedule[:duration] = duration
    schedule[:user_id] = user_id
    schedule[:cal_rrule] = rrule || ""
    schedule[:selectable] = selectable
    schedule
  end

  # Consolidates multiple schedules when they overlap within the given time range.
  # @param schedules [Array<Schedule>, CollectionProxy<Schedule>] the schedules to consolidate
  # @param start_time [Time] the start time of the range
  # @param end_time [Time] the end time of the range
  # @return [Array<Schedule>] the consolidated schedules
  def self.consolidate_schedules(schedules, start_time, end_time)
    occurrence_intervals = schedules.flat_map do |schedule|
      icecube_schedule = schedule.make_icecube_schedule
      occurrences = icecube_schedule.occurrences_between(start_time, end_time)
      occurrences.map do |occurrence|
        ScheduleInterval.new(occurrence, occurrence + schedule.duration, schedule)
      end
    end

    return [] if occurrence_intervals.empty?

    consolidated_occurrences = consolidate_occurrences(occurrence_intervals.sort_by(&:start))

    # Each occurrence could have a different duration so we need to create a new schedule for each occurrence.
    consolidated_schedules = []
    consolidated_occurrences.each_with_index do |occurrence, index|
      consolidated_schedules << Schedule.new(name: "Consolidated Schedule #{index + 1}",
        start_time: occurrence.start,
        end_time: occurrence.end,
        duration: ActiveSupport::Duration.build((occurrence.end - occurrence.start).to_i),
        user_id: schedules.first.user_id)
    end
    consolidated_schedules
  end

  # Merges overlapping occurrences.
  # @param occurrence_intervals [Array<Struct<ScheduleInterval>>] the sorted array of occurrences to merge
  # @return [Array<Struct<ScheduleInterval>>] the merged occurrences
  def self.consolidate_occurrences(occurrence_intervals)
    return [] if occurrence_intervals.empty?

    consolidated_intervals = [occurrence_intervals.first]
    occurrence_intervals.each do |interval|
      if interval.start <= consolidated_intervals.last.end
        consolidated_intervals[-1] = ScheduleInterval.new(consolidated_intervals.last.start, [consolidated_intervals.last.end, interval.end].max)
      else
        consolidated_intervals << interval
      end
    end
    consolidated_intervals
  end

  # Sets the end time based on the first occurrence and duration.
  # @param duration [Integer] the duration of the event in seconds
  def set_end_time(duration = self.duration)
    self.end_time = make_icecube_schedule.first + duration
  end

  # Finds overlapping schedules within the given time range.
  # @param schedules [Array<Schedule>] the schedules to check for overlaps
  # @param start_time [Time] the start time of the range
  # @param end_time [Time] the end time of the range
  # @return [Array<Struct<ScheduleInterval>>] the overlapping intervals
  def self.find_overlaps(schedules, start_time, end_time)
    occurrences = schedules.flat_map do |schedule|
      schedule.make_icecube_schedule.occurrences_between(start_time, end_time).flat_map do |occurrence|
        occurrence_end = schedule.end_time
        [ScheduleStart.new(occurrence, schedule),
          ScheduleEnd.new(occurrence_end, schedule)]
      end
    end
    schedule_events = occurrences.sort_by { |occurrence| occurrence.date }

    # Create a stack for each user to keep track of their availability.
    stacks = schedule_events.each_with_object({}) do |event, stacks|
      stacks[event.schedule.user_id] ||= []
    end
    ideal_intervals = []

    schedule_events.each do |event|
      if event.is_a?(ScheduleStart)
        if stacks[event.schedule.user_id].empty?
          stacks[event.schedule.user_id].push(event)
          ideal_top = ideal_intervals.last
          if ideal_top&.is_a?(ScheduleStart) && ideal_top.schedule.user_id != event.schedule.user_id
            ideal_intervals.pop
          end
          unless stacks.any? { |_, stack| stack.empty? }
            ideal_intervals.push(event)
          end
        elsif stacks[event.schedule.user_id].last.is_a?(ScheduleStart)
          stacks[event.schedule.user_id].push(event)
        else
          raise "Stack error: ScheduleEnd in stack."
        end
      elsif event.is_a?(ScheduleEnd)
        if stacks[event.schedule.user_id].last.is_a?(ScheduleStart)
          stacks[event.schedule.user_id].pop
          if stacks[event.schedule.user_id].empty? && ideal_intervals.last.is_a?(ScheduleStart)
            ideal_intervals.push(event)
          end
        elsif stacks[event.schedule.user_id].last.is_a?(ScheduleEnd)
          raise "Stack error: ScheduleEnd in stack."
        else # nil
          raise "Stack error: ScheduleEnd without ScheduleStart."
        end
      else
        raise "Event error: Unknown event type."
      end
    end

    overlaps = []

    while ideal_intervals.length > 0
      curr_start = ideal_intervals.shift
      unless curr_start.is_a?(ScheduleStart)
        throw "Ideal interval error: Expected ScheduleStart, got #{curr_start.class}."
      end

      curr_end = ideal_intervals.shift
      unless curr_end.is_a?(ScheduleEnd)
        throw "Ideal interval error: Expected ScheduleEnd, got #{curr_end.class}."
      end

      overlaps.push(ScheduleInterval.new(curr_start.date, curr_end.date))
    end

    overlaps
  end

  # Creates a new schedule with default parameters for a given user.
  # @param user_id [Integer] the ID of the user
  # @return [Schedule] the new schedule
  def self.new_default(user_id)
    Schedule.new(**DEFAULT_PARAMS, user_id: user_id)
  end

  def touch_availabilities
    availabilities.each(&:touch)
  end
end
