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
      format.html { render partial: "shared/creation_modal", locals: CreationLocalsBuilderService.call(params, Current.user) }
    end
  end

  private

  def calendar_params
    params[:schedule_ids] = params[:schedule_ids].present? ? params[:schedule_ids].split(",") : []
    params.permit(:start, :end, :user_id, :group_id, :schedule_id, :availability_id, :game_session_id, :game_proposal_id, :exclude_availabilities, schedule_ids: [])
  end

  def user_not_authorized
    render json: {error: t("pundit.not_authorized")}, status: :unauthorized
  end

  def not_found
    render json: {error: "Resource not found."}, status: :not_found
  end
end
