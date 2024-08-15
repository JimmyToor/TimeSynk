class UserAvailabilitiesController < ApplicationController
  before_action :set_user_availability, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized

  # GET /user_availabilities or /user_availabilities.json
  def index
    @user_availabilities = policy_scope(UserAvailability)
  end

  # GET /user_availabilities/1 or /user_availabilities/1.json
  def show
    @availabilities = policy_scope(Availability)
  end

  # GET /user_availabilities/new
  def new
    @availabilities = policy_scope(Availability)
  end

  # GET /user_availabilities/1/edit
  def edit
    @availabilities = policy_scope(Availability)
  end

  # POST /user_availabilities or /user_availabilities.json
  def create
    @availability = Availability.find_by!(id: user_availability_params[:availability_id])
    @user_availability = @availability.build_user_availability(user_availability_params)

    respond_to do |format|
      if @user_availability.save
        format.html { redirect_to user_availability_url(@user_availability), notice: "User availability was successfully created." }
        format.json { render :show, status: :created, location: @user_availability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_availability.errors, status: :unprocessable_entity }
      end
    end
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

  # DELETE /user_availabilities/1 or /user_availabilities/1.json
  def destroy
    @user_availability.destroy!

    respond_to do |format|
      format.html { redirect_to user_availabilities_url, notice: "User availability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_user_availability
    @user_availability = UserAvailability.find_by(user_id: Current.user.id)
  end

    # Only allow a list of trusted parameters through.
  def user_availability_params
    params.require(:user_availability).permit(:user_id, :availability_id)
  end
end
