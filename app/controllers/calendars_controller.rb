class CalendarsController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  # TODO: Add authorizations and scopes

  def show
    Rails.logger.debug "CalendarsController#show: params: #{params.inspect}"
    @calendars = []
    if params[:group_id].present?
      group = Group.find(params[:group_id])
      @calendars = make_group_calendars(group)
      # TODO: get group's schedules between start and end dates as one calendar per user and per proposal
    end
    if params[:schedule_id].present?
      schedule = Schedule.find(params[:schedule_id])
      @calendars << make_schedule_calendar(schedule)
    end
    if params[:availability_id].present?
      availability = Availability.find(params[:availability_id])
      @calendars << make_availability_calendar(availability)
    end
    if params[:game_session_id].present?
      game_session = GameSession.find(params[:game_session_id])
      @calendars << make_game_session_calendar(game_session)
    end
    if params[:game_proposal_id].present?
      game_proposal = GameProposal.find(params[:game_proposal_id])
      @calendars << make_game_proposal_calendar(game_proposal)
    end
    render json: @calendars.as_json
  end

  private

  def make_schedule_calendar(schedule)
    Rails.logger.debug "CalendarsController#make_schedule_calendar: schedule: #{schedule.inspect}"
    calendar = Calendar.new(
      schedules: [schedule.make_calendar_schedule],
      name: "Schedule: #{schedule.name}",
      id: "schedule-#{schedule.id}-#{schedule.user.id}",
      type: :schedule,
    )
    Rails.logger.debug "CalendarsController#make_schedule_calendar: calendar: #{calendar.inspect}"
    calendar
  end

  def make_availability_calendar(availability)
    Rails.logger.debug "CalendarsController#make_availability_calendar: availability: #{availability.inspect}"
    calendar = Calendar.new(
      schedules: availability.schedules.map(&:make_calendar_schedule),
      name: "Availability: #{availability.name}",
      username: availability.user.username,
      id: "availability-#{availability.id}-#{availability.user.id}",
      type: :availability,
    )
    Rails.logger.debug "CalendarsController#make_availability_calendar: calendar: #{calendar.inspect}"
    calendar
  end

  def make_group_calendars(group)
    Rails.logger.debug "CalendarsController#make_group_calendars: group: #{group.inspect}"
    calendars = []
    group.users.each do |user|
      availability = user.get_nearest_group_availability(group)
      calendars << make_availability_calendar(availability)
    end
    group.game_proposals.each do |game_proposal|
      calendars << make_game_proposal_calendar(game_proposal)
    end
    Rails.logger.debug "CalendarsController#make_group_calendars: calendars: #{calendars.inspect}"
    calendars
  end

  def make_game_session_calendar(game_session)
    session_schedule = game_session.make_calendar_schedule
    Calendar.new(
      schedules: [session_schedule],
      name: session_schedule[:name].to_s,
      id: "session-#{game_session.id}",
      type: :game_session,
    )
  end

  def make_game_proposal_calendar(game_proposal)
    Calendar.new(
      schedules: game_proposal.make_calendar_schedules,
      name: Game.find(game_proposal.game_id).name.to_s,
      id: "proposal-#{game_proposal.id}",
      type: :game_proposal,
    )
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_availability
    @availability = Availability.find(params[:availability_id])
  end

  def set_schedule
    @schedule = Schedule.find(params[:schedule_id])
  end

  def calendar_params
    params.require(:calendar).permit(:user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id)
  end

end
