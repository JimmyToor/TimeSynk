class UserAvailabilitiesController < ApplicationController
  before_action :set_user_availability, only: %i[show edit update]
  skip_after_action :verify_authorized, only: %i[index]

  # GET /user_availabilities or /user_availabilities.json
  def index
    @user_availabilities = policy_scope(UserAvailability)
  end

  # GET /user_availabilities/1 or /user_availabilities/1.json
  def show
    @availabilities = policy_scope(Availability)
  end

  # GET /user_availabilities/1/edit
  def edit
    @availabilities = policy_scope(Availability)
  end

  # PATCH/PUT /user_availabilities/1 or /user_availabilities/1.json
  def update
    respond_to do |format|
      if @user_availability.update(user_availability_params)
        format.html { redirect_to user_availability_url, notice: "User availability was successfully updated." }
        format.json { render :show, status: :ok, location: @user_availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_availability
    @user_availability = authorize(UserAvailability.find_by(user_id: Current.user.id))
  end

  # Only allow a list of trusted parameters through.
  def user_availability_params
    params.require(:user_availability).permit(:user_id, :availability_id)
  end
end
