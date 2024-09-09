class CalendarsController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  # TODO: Add authorizations and scopes
  # TODO: Add caching

  def show
    @calendars = CalendarCreationService.new(calendar_params, Current.user).create_calendars

    render json: @calendars.as_json
  end

  private

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
    params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id)
  end

end
