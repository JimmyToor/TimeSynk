# frozen_string_literal: true

class CalendarCreationService
  def initialize(params, user)
    @params = params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id)
    @user = user
  end

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
      @calendars.concat(make_group_calendars(Group.find(@params[:group_id]), start_date: @params[:start], end_date: @params[:end]))
    end

    if @params[:schedule_id].present?
      @calendars << make_schedule_calendar(Schedule.find(@params[:schedule_id]))
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
      game_proposal.group.users.each do |user|
        @calendars << make_availability_calendar(user.nearest_proposal_availability(game_proposal))
      end
    end
    @calendars
  end

  private

  def make_schedule_calendar(schedule)
    Calendar.new(
      schedules: [schedule.make_calendar_schedule],
      name: "Schedule: #{schedule.name}",
      title: schedule.user.username,
      id: "calendar_schedule_#{schedule.id}",
      type: :schedule
    )
  end

  def make_availability_calendar(availability) # TODO: Merge schedules for readability where possible (e.g. if two schedules are adjacent)
    Calendar.new(
      schedules: availability.schedules.map { |schedule|
        icecube_schedule = schedule.make_icecube_schedule
        schedule.make_calendar_schedule(icecube_schedule) if schedule.in_range(icecube_schedule: icecube_schedule, start_date: @params[:start], end_date: @params[:end])
      }.compact,
      name: "Availability: #{availability.name}",
      title: availability.user.username,
      id: "calendar_availability_#{availability.id}",
      type: :availability
    )
  end

  def make_group_calendars(group, start_date: nil, end_date: nil)
    calendars = []
    group.users.each do |user|
      availability = user.nearest_group_availability(group)
      calendars << make_availability_calendar(availability)
    end
    group.game_proposals.each do |game_proposal|
      calendars << make_game_proposal_calendar(game_proposal, start_date: start_date, end_date: end_date)
    end
    calendars
  end

  def make_game_session_calendar(game_session)
    session_schedule = game_session.make_calendar_schedule
    Calendar.new(
      schedules: [session_schedule],
      name: session_schedule[:name].to_s,
      id: "calendar_session_#{game_session.id}",
      type: :game
    )
  end

  def make_game_proposal_calendar(game_proposal, start_date: nil, end_date: nil)
    Calendar.new(
      schedules: game_proposal.make_calendar_schedules(start_date: start_date, end_date: end_date),
      name: Game.find(game_proposal.game_id).name.to_s,
      id: "calendar_proposal_#{game_proposal.id}",
      type: :game
    )
  end
end
