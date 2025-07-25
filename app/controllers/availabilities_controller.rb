class AvailabilitiesController < ApplicationController
  before_action :set_availability, only: %i[show edit update destroy]
  before_action :set_schedules, only: %i[new edit create]
  before_action :add_no_schedules_flash, only: %i[new edit create]

  # GET /availabilities
  def index
    @availabilities = params[:query].present? ? policy_scope(Availability).search(params[:query]) : policy_scope(Availability)
    @pagy, @availabilities = pagy(@availabilities)
    respond_to do |format|
      format.html { render :index, locals: {availabilities: @availabilities} }
      format.turbo_stream
    end
  end

  # GET /availabilities/1
  def show
  end

  # GET /availabilities/new
  def new
    @availability = authorize(Availability.new(user: Current.user))
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

  # POST /availabilities
  def create
    @availability = Availability.new(availability_params)
    authorize(@availability)
    add_no_schedules_flash

    respond_to do |format|
      if @availability.save
        format.html { redirect_to availability_url(@availability), success: {message: "Availability was successfully created."} }
      else
        flash.now[:alert] = {message: I18n.t("availability.create.error"),
                             options: {list_items: @availability.errors.full_messages}}
        format.html { render :new, locals: {schedules: @schedules, availability: @availability}, status: :unprocessable_entity }
        format.turbo_stream { render "create_fail" }
      end
    end
  end

  # PATCH/PUT /availabilities/1
  def update
    respond_to do |format|
      if @availability.update(availability_params)
        format.html { redirect_to availability_url(@availability), notice: "Availability was successfully updated." }
      else
        flash.now[:alert] = {message: I18n.t("availability.update.error"),
                             options: {list_items: @availability.errors.full_messages}}
        format.html { render :edit, locals: {schedules: @schedules, availability: @availability}, status: :unprocessable_entity }
        format.turbo_stream { render "update_fail" }
      end
    end
  end

  # DELETE /availabilities/1
  def destroy
    respond_to do |format|
      if @availability.destroy
        format.html { redirect_to availabilities_url, notice: "Availability was successfully destroyed." }
        format.turbo_stream
      else
        format.html { redirect_to availabilities_url, alert: "Availability could not be destroyed." }
        format.turbo_stream { render :destroy_fail }
      end
    end
  end

  private

  def set_availability
    @availability = authorize(Availability.find(params[:id]))
  end

  def set_schedules
    @schedules = policy_scope(Schedule)
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
      flash.now[:info] = {message: I18n.t("availability.no_schedules")}
    end
  end
end
