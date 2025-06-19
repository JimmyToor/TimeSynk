class AvailabilitySchedulesController < ApplicationController
  before_action :set_availability, only: %i[index]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /availability_schedules or /availability_schedules.json
  def index
    authorize(@availability, :show?, policy_class: AvailabilityPolicy)
    @availability_schedules = @availability.availability_schedules.includes(:schedule)
    respond_to do |format|
      format.json { render :index, status: :ok }
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def availability_schedule_params
    params.require(:availability_schedule).permit(:availability_id, :schedule_id)
  end

  def set_availability
    @availability = if params[:availability_id].present?
      Availability.find(params[:availability_id])
    else
      Current.user.availabilities.build(Availability::DEFAULT_PARAMS)
    end
  end
end
