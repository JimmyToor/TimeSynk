class UserAvailabilitiesController < ApplicationController
  before_action :set_user_availability, only: %i[show edit update]

  # GET /user_availabilities
  def index
    @user_availabilities = policy_scope(UserAvailability)
  end

  # GET /user_availabilities/1
  def show
    @availabilities = policy_scope(Availability)
  end

  # GET /user_availabilities/1/edit
  def edit
    @availabilities = policy_scope(Availability)
  end

  # PATCH/PUT /user_availabilities/1
  def update
    respond_to do |format|
      if @user_availability.update(user_availability_params)
        format.html { redirect_to user_availability_url, notice: "User availability was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user_availability
    @user_availability = authorize(UserAvailability.find_by(user_id: Current.user.id))
  end

  # Only allow a list of trusted parameters through.
  def user_availability_params
    params.require(:user_availability).permit(:user_id, :availability_id)
  end
end
