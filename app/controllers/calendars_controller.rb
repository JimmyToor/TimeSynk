class CalendarsController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def show
    @calendars = CalendarCreationService.call(calendar_params, Current.user)
    render json: @calendars.as_json
  end

  def new
    respond_to do |format|
      format.html { render partial: "shared/creation_modal", locals: get_locals }
    end
  end

  private

  def get_locals
    locals = {}
    locals[:schedule] = Schedule.new_default(Current.user.id)

    locals[:date] = params[:date].present? ? Date.parse(params[:date]) : Date.today

    if params[:game_proposal_id].present?
      game_proposal = GameProposal.find(params[:game_proposal_id])
      if GameProposalPolicy.new(Current.user, game_proposal).create_game_session?
        locals[:game_proposal] = game_proposal
        locals[:initial_game_proposal] = game_proposal
      end
    elsif params[:group_id].present?
      group = Group.find(params[:group_id])
      if group.game_proposals.any?
        locals[:groups] = [group]
        game_proposals = group.game_proposals_user_can_create_sessions_for(Current.user)
        locals[:game_proposals] = game_proposals
        locals[:initial_game_proposal] = game_proposals.first
      end
    elsif params[:user_id].present?
      user = User.find(params[:user_id])
      game_proposals = user.game_proposals_user_can_create_sessions_for
      if game_proposals.any?
        locals[:groups] = game_proposals.map(&:group).uniq
        locals[:game_proposals] = game_proposals
        locals[:initial_game_proposal] = game_proposals.first
      end
    end
    locals
  end

  def calendar_params
    params[:schedule_ids] = params[:schedule_ids].present? ? params[:schedule_ids].split(",") : []
    params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id, :exclude_availabilities, schedule_ids: [])
  end

  def user_not_authorized
    render json: {error: "You are not authorized to perform this action."}, status: :unauthorized
  end

  def not_found
    render json: {error: "Resource not found."}, status: :not_found
  end
end
