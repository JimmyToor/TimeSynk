class AvailabilitiesController < ApplicationController
  before_action :set_availability, only: %i[show edit update destroy]
  before_action :set_schedules, only: %i[new edit create]

  # GET /availabilities or /availabilities.json
  def index
    @availabilities = params[:query].present? ? policy_scope(Availability).search(params[:query]) : policy_scope(Availability)
    authorize(@availabilities)
    @pagy, @availabilities = pagy(@availabilities)
    respond_to do |format|
      format.html { render :index, locals: {pagy: @pagy, availabilities: @availabilities} }
      format.turbo_stream
    end
  end

  # GET /availabilities/1 or /availabilities/1.json
  def show
  end

  # GET /availabilities/new
  def new
    @availability = Availability.new(user: Current.user)
    @pagy, @schedules = pagy(@schedules)

    respond_to do |format|
      format.html { render :new, locals: {schedules: @schedules, availability: @availability} }
    end
  end

  # GET /availabilities/1/edit
  def edit
    @pagy, @schedules = pagy(@schedules)
    add_no_schedules_flash
    respond_to do |format|
      format.html { render :edit, locals: {schedules: @schedules, availability: @availability} }
    end
  end

  # POST /availabilities or /availabilities.json
  def create
    @availability = Availability.new(availability_params)
    authorize(@availability)
    respond_to do |format|
      if @availability.save
        format.html { redirect_to availability_url(@availability), success: {message: "Availability was successfully created."} }
        format.json { render :show, status: :created, location: @availability }
      else
        format.html { render :new, locals: {schedules: @schedules, availability: @availability}, status: :unprocessable_entity }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /availabilities/1 or /availabilities/1.json
  def update
    respond_to do |format|
      if @availability.update(availability_params)
        format.html { redirect_to availability_url(@availability), notice: "Availability was successfully updated." }
        format.json { render :show, status: :ok, location: @availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /availabilities/1 or /availabilities/1.json
  def destroy
    respond_to do |format|
      if @availability.destroy
        format.html { redirect_to availabilities_url, notice: "Availability was successfully destroyed." }
        format.json { head :no_content }
        format.turbo_stream
      else
        format.html { redirect_to availabilities_url, alert: "Availability could not be destroyed." }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
        format.turbo_stream { render :destroy_fail }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_availability
    @availability = authorize(Availability.find(params[:id]))
  end

  def set_schedules
    @schedules = authorize(policy_scope(Schedule))
  end

  # Only allow a list of trusted parameters through.
  def availability_params
    params.require(:availability).permit(:name,
      :user_id,
      :description,
      availability_schedules_attributes: [:id, :schedule_id, :_destroy])
  end

  def add_no_schedules_flash
    if Current.user.schedules.count == 0
      flash.now[:info] = {message: "You can create schedules to indicate the times you're available. The schedules you select will make up your availability. Get started by creating a new schedule."}
    end
  end
end
