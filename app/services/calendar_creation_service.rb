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
  end

  # Orchestrates the creation of different calendar types based on the initialized parameters.
  #
  # @return [Array<Calendar>] An array of generated Calendar objects, ready to be parsed for FullCalendar.
  def call
    @calendars = []
    if @params[:user_id].present?
      GameProposal.joins(group: :users)
        .where(users: {id: @params[:user_id]})
        .joins(:game_sessions)
        .distinct.each do |game_proposal|
        @calendars << make_game_proposal_calendar(game_proposal)
      end
    end

    if @params[:group_id].present?
      @calendars.concat(make_group_calendars(Group.find(@params[:group_id])))
    end

    if @params[:schedule_id].present?
      @calendars << make_schedule_calendar(Schedule.find(@params[:schedule_id]))
    end

    if @params[:schedule_ids].present?
      @calendars.concat(@params[:schedule_ids].map { |id| make_schedule_calendar(Schedule.find(id)) })
    end

    if @params[:availability_id].present?
      @calendars << make_availability_calendar(Availability.find(@params[:availability_id]))
    end

    if @params[:game_session_id].present?
      @calendars << make_game_session_calendar(GameSession.find(@params[:game_session_id]))
    end

    if @params[:game_proposal_id].present?
      game_proposal = GameProposal.find(@params[:game_proposal_id])
      @calendars << make_game_proposal_calendar(game_proposal) unless game_proposal.game_sessions.empty?
      @calendars.concat(make_availability_calendars(game_proposal.group.users, game_proposal: game_proposal)) unless @params[:exclude_availabilities]
    end
    @calendars
  end

  private

  # Creates a calendar for a given schedule.
  #
  # @param schedule [Schedule] the schedule to create a calendar for
  # @return [Calendar] the created calendar
  def make_schedule_calendar(schedule)
    Pundit.authorize(@user, schedule, :show?)
    Calendar.new(
      schedules: [schedule.make_calendar_schedule],
      name: schedule.name.to_s,
      id: "calendar_schedule_#{schedule.id}",
      type: :schedule
    )
  end

  # Creates calendars for a given group.
  #
  # @param group [Group] the group to create calendars for
  # @return [Array<Calendar>] the created calendars
  def make_group_calendars(group)
    Pundit.authorize(@user, group, :show?)
    calendars = []
    calendars.concat(make_availability_calendars(group.users, group: group)) unless @params[:exclude_availabilities]
    group.game_proposals.reject { |proposal| proposal.game_sessions.empty? }.each do |game_proposal|
      calendars << make_game_proposal_calendar(game_proposal)
    end
    calendars
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

      calendar_schedules = consolidated_schedules.map { |schedule| schedule.make_calendar_schedule(selectable: schedule.user_id == @user.id) }
      calendars << make_availability_calendar(availability, calendar_schedules: calendar_schedules)
    end
    calendars << make_overlap_calendar(all_schedules) if overlap_possible && calendars.length > 1
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
    Pundit.authorize(@user, game_session.game_proposal, :show?)
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
    Pundit.authorize(@user, game_proposal, :show?)
    Calendar.new(
      schedules: game_proposal.make_calendar_schedules(start_time: @params[:start], end_time: @params[:end]),
      name: Game.find(game_proposal.game_id).name.to_s,
      id: "calendar_proposal_#{game_proposal.id}",
      type: :game
    )
  end
end
