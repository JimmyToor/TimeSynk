# frozen_string_literal: true

# Service responsible for creating various types of FullCalendar-compatible calendar objects.
class CalendarCreationService
  def initialize(params, user)
    @params = params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id, schedule_ids: [])
    @user = user
  end

  # Creates calendars based on the provided parameters.
  #
  # @return [Array<Calendar>] the created calendars
  def create_calendars
    @calendars = []
    if @params[:user_id].present?
      User.find(@params[:user_id]).groups.each do |group|
        group.game_proposals.each do |game_proposal|
          @calendars << make_game_proposal_calendar(game_proposal)
        end
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
      @calendars << make_game_proposal_calendar(game_proposal)
      @calendars.concat(make_availability_calendars(game_proposal.group.users, game_proposal: game_proposal))
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
      name: "#{schedule.name}",
      id: "calendar_schedule_#{schedule.id}",
      type: :schedule
    )
  end

  # Creates calendars for a given group.
  #
  # @param group [Group] the group to create calendars for
  # @return [Array<Calendar>] the created calendars
  def make_group_calendars(group)
    Pundit.authorize(@user, group, :edit?)
    calendars = []
    calendars.concat(make_availability_calendars(group.users, group: group))
    group.game_proposals.each do |game_proposal|
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

      if schedule.in_range(icecube_schedule: icecube_schedule)
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
      type: :availability
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
      name: session_schedule[:name].to_s,
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
