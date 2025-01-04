class CalendarsController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  # TODO: Add authorizations and scopes
  # TODO: Add caching

  def show
    @calendars = CalendarCreationService.new(calendar_params, Current.user).create_calendars
    render json: @calendars.as_json
  end

  def new
    respond_to do |format|
      format.html { render partial:"shared/creation_modal", locals: set_locals, turbo_frame: "modal_frame" }
    end
  end

  private

  def set_locals
    locals = {}
    locals[:schedule] = Schedule.new(user_id: Current.user.id)

    if params[:game_proposal_id].present?
      game_proposal = GameProposal.find(params[:game_proposal_id])
      locals[:game_proposal] = game_proposal
      locals[:initial_game_proposal] = game_proposal
    elsif params[:group_id].present?
      group = Group.find(params[:group_id])
      if group.game_proposals.any?
        locals[:group] = group
        locals[:game_proposals] = group.game_proposals
        locals[:initial_game_proposal] = group.game_proposals.first
      end
    elsif params[:user_id].present?
      user = User.find(params[:user_id])
      if user.game_proposals.any?
        locals[:groups] = user.groups
        locals[:game_proposals] = user.game_proposals
        locals[:initial_game_proposal] = user.game_proposals.first
      end
    end
    locals
  end

  def calendar_params
    params[:schedule_ids] = params[:schedule_ids].split(",") if params[:schedule_ids].present?
    params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id, schedule_ids: [])
  end
end
