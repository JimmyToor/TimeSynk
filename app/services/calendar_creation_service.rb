# frozen_string_literal: true

# Creates various types of FullCalendar-compatible calendar data
# based on different parameters like users, groups, schedules, availabilities,
# game sessions, or game proposals.
#
# @note Contiguous schedules belonging to the same user availability may be consolidated
#   into fewer events if they are not the sole focus (e.g., when viewing group availability).
#
# @example Generating calendars for a user's groups
#   params = ActionController::Parameters.new(start: "2023-01-01", end: "2023-01-31", user_id: 1)
#   user = User.find(1)
#   calendars = CalendarCreationService.call(params, user)
#
# @example Generating a calendar for a specific schedule
#   params = ActionController::Parameters.new(start: "2023-01-01", end: "2023-01-31", schedule_id: 5)
#   user = User.find(1) # Assuming user 1 has permission to view schedule 5
#   calendars = CalendarCreationService.call(params, user) # Returns an array with one Calendar object
class CalendarCreationService < ApplicationService
  # Initializes the service with permitted parameters and the current user.
  #
  # @param params [ActionController::Parameters] Parameters controlling calendar generation.
  # @option params [String] :start The start date/time for the calendar view (ISO 8601 format).
  # @option params [String] :end The end date/time for the calendar view (ISO 8601 format).
  # @option params [Integer] :user_id ID of the user for whom to generate group calendars (includes group availabilities).
  # @option params [Integer] :group_id ID of the group for which to generate calendars.
  # @option params [Integer] :schedule_id ID of a specific schedule to generate a calendar for.
  # @option params [Array<Integer>] :schedule_ids IDs of multiple schedules to generate calendars for.
  # @option params [Integer] :availability_id ID of a specific availability to generate a calendar for.
  # @option params [Integer] :game_session_id ID of a game session to generate a calendar for.
  # @option params [Integer] :game_proposal_id ID of a game proposal to generate a calendar for (includes proposal availabilities).
  # @option params [Boolean] :exclude_availabilities Whether to exclude availabilities from the generated calendars.
  # @param user [User] The user requesting the calendar data (used for authorization).
  def initialize(params, user)
    @params = params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id, :exclude_availabilities, schedule_ids: [])
    @user = user
    @calendars = []
  end

  # Orchestrates the creation of different calendar types based on the initialized parameters.
  #
  # @return [Array<Calendar>] An array of generated Calendar objects, ready to be parsed for FullCalendar.
  def call
    process_user_calendars if @params[:user_id].present?
    process_group_calendars if @params[:group_id].present?
    process_schedule_calendars if @params[:schedule_id].present? || @params[:schedule_ids].present?
    process_availability_calendar if @params[:availability_id].present?
    process_game_session_calendar if @params[:game_session_id].present?
    process_game_proposal_calendars if @params[:game_proposal_id].present?
    @calendars
  end

  private

  def process_user_calendars
    game_proposals = GameProposal.joins(group: :users)
      .includes(:game, :game_sessions)
      .where(users: {id: @params[:user_id]})
      .distinct
    game_proposals.each do |game_proposal|
      @calendars << make_game_proposal_calendar(game_proposal)
    end
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing user calendars for #{@user.inspect}: #{e.message}")
  end

  def process_group_calendars
    group = Group.includes(game_proposals: [:game_sessions, :game]).find_by(id: @params[:group_id])
    return unless group

    raise Pundit::NotAuthorizedError unless authorized?(group)
    @calendars.concat(make_availability_calendars(group.users, group: group)) unless @params[:exclude_availabilities]
    group.game_proposals.each do |game_proposal|
      @calendars << make_game_proposal_calendar(game_proposal)
    end
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing group calendars for #{@user.inspect}: #{e.message}")
  end

  def process_schedule_calendars
    schedules = if @params[:schedule_id].present?
      Schedule.where(id: @params[:schedule_id])
    else
      Schedule.where(id: @params[:schedule_ids])
    end
    schedules.each do |schedule|
      @calendars << make_schedule_calendar(schedule)
    end
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing schedule calendars for #{@user.inspect}: #{e.message}")
  end

  def process_availability_calendar
    availability = Availability.includes(:schedules).find_by(id: @params[:availability_id])
    return unless availability

    @calendars << make_availability_calendar(availability)
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing availability calendar for #{@user.inspect}: #{e.message}")
  end

  def process_game_session_calendar
    game_session = GameSession.find_by(id: @params[:game_session_id])
    return unless game_session

    @calendars << make_game_session_calendar(game_session)
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing game session calendar for #{@user.inspect}: #{e.message}")
  end

  def process_game_proposal_calendars
    game_proposal = GameProposal.includes(:game_sessions, group: :users).find_by(id: @params[:game_proposal_id])
    return unless game_proposal

    @calendars << make_game_proposal_calendar(game_proposal) unless game_proposal.game_sessions.empty?
    unless @params[:exclude_availabilities]
      @calendars.concat(make_availability_calendars(game_proposal.group.users, game_proposal: game_proposal))
    end
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error("Authorization error processing game proposal calendars for #{@user.inspect}: #{e.message}")
  end

  # Creates a calendar for a given schedule.
  #
  # @param schedule [Schedule] the schedule to create a calendar for
  # @return [Calendar] the created calendar
  def make_schedule_calendar(schedule)
    Calendar.new(
      schedules: [schedule.make_calendar_schedule(selectable: authorized?(schedule))],
      name: schedule.name.to_s,
      id: "calendar_schedule_#{schedule.id}",
      type: :schedule
    )
  end

  # Creates a calendar for a given availability.
  #
  # @param availability [Availability] the availability to create a calendar for
  # @param calendar_schedules [Array<CalendarSchedule>] the calendar schedules (optional)
  # @param consolidate [Boolean] whether to consolidate schedules, does not apply if calendar_schedules is passed (optional)
  # @return [Calendar] the created calendar
  def make_availability_calendar(availability, calendar_schedules: [], consolidate: false)
    if calendar_schedules.empty?
      calendar_schedules = if consolidate
        Schedule.consolidate_schedules(availability.schedules, @params[:start], @params[:end]).map { |schedule| schedule.make_calendar_schedule }
      else
        make_calendar_schedules(availability.schedules)
      end
    end

    Calendar.new(
      schedules: calendar_schedules,
      name: "Availability: #{availability.name}",
      title: availability.user.username,
      id: "calendar_availability_#{availability.id}",
      type: :availability
    )
  end

  # Creates availability calendars for each user in the list of users.
  #
  # @param users [Array<User>, CollectionProxy] the users to create availability calendars for
  # @param group [Group] the group to use for availability context (optional)
  # @param game_proposal [GameProposal] the game proposal to use for availability context (optional)
  # @return [Array<Calendar>] the created calendars
  def make_availability_calendars(users, group: nil, game_proposal: nil)
    all_schedules = []
    calendars = []
    overlap_possible = true

    users.each do |user|
      availability = if group.present?
        user.nearest_group_availability(group)
      elsif game_proposal.present?
        user.nearest_proposal_availability(game_proposal)
      else
        user.user_availability.availability
      end
      next if availability.schedules == []

      consolidated_schedules = Schedule.consolidate_schedules(availability.schedules, @params[:start], @params[:end])
      # If a single user has no availability, there can't be overlapping times
      if consolidated_schedules.empty?
        overlap_possible = false
      else
        all_schedules.concat(consolidated_schedules)
      end

      selectable = authorized?(availability)

      calendar_schedules = consolidated_schedules.map { |schedule|
        schedule.make_calendar_schedule(selectable: selectable)
      }
      calendars << make_availability_calendar(availability, calendar_schedules: calendar_schedules)
    end

    begin
      overlap_calendars = make_overlap_calendar(all_schedules) if overlap_possible && calendars.length > 1
      calendars << overlap_calendars if overlap_calendars.present?
    rescue ScheduleOverlapError => e
      Rails.logger.error("ScheduleOverlapError: #{e.message}. Schedules: #{all_schedules.inspect}")
    end

    calendars
  end

  # Creates calendar schedules for each schedule in the list of schedules.
  #
  # @param schedules [Array<Schedule>] the schedules to create calendar schedules for
  # @return [Array<CalendarSchedule>] the created calendar schedules
  def make_calendar_schedules(schedules)
    schedules.map { |schedule|
      icecube_schedule = schedule.make_icecube_schedule

      if schedule.in_range(icecube_schedule: icecube_schedule, start_time: @params[:start], end_time: @params[:end])
        schedule.make_calendar_schedule(icecube_schedule)
      end
    }.compact
  end

  # Creates an overlap calendar for a list of schedules.
  #
  # @param schedules [Array<Schedule>] the schedules to find overlaps for
  # @return [Calendar] the created overlap calendar
  def make_overlap_calendar(schedules)
    overlaps = Schedule.find_overlaps(schedules, @params[:start], @params[:end])

    overlap_schedules = overlaps.map.with_index { |overlap, index|
      Schedule.new(name: "Ideal Time Schedule #{index + 1}",
        start_time: overlap.start,
        end_time: overlap.end,
        duration: ActiveSupport::Duration.build(overlap.end - overlap.start),
        user_id: nil).make_calendar_schedule(selectable: false)
    }
    Calendar.new(
      schedules: overlap_schedules,
      name: "Everyone Available",
      id: "calendar_ideal",
      type: :ideal
    )
  end

  # Creates a calendar for a given game session.
  #
  # @param game_session [GameSession] the game session to create a calendar for
  # @return [Calendar] the created calendar
  def make_game_session_calendar(game_session)
    raise Pundit::NotAuthorizedError unless authorized?(game_session)
    session_schedule = game_session.make_calendar_schedule
    Calendar.new(
      schedules: [session_schedule],
      name: session_schedule[:name],
      id: "calendar_session_#{game_session.id}",
      type: :game
    )
  end

  # Creates a calendar for a given game proposal.
  #
  # @param game_proposal [GameProposal] the game proposal to create a calendar for
  # @return [Calendar] the created calendar
  def make_game_proposal_calendar(game_proposal)
    raise Pundit::NotAuthorizedError unless authorized?(game_proposal)
    Calendar.new(
      schedules: game_proposal.make_calendar_schedules(start_time: @params[:start], end_time: @params[:end]),
      name: Game.find(game_proposal.game_id).name.to_s,
      id: "calendar_proposal_#{game_proposal.id}",
      type: :game
    )
  end

  # Checks if the user is authorized to view the given record.
  #
  # @param record [ApplicationRecord] the record to check authorization for
  # @return [Boolean] true if authorized, false otherwise
  def authorized?(record)
    true if Pundit.authorize(@user, record, :show?)
  rescue Pundit::NotAuthorizedError
    false
  end
end
