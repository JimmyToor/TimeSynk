class AvailabilitiesController < ApplicationController
  add_flash_types :success
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

    if @availability.save
      redirect_to availability_path(@availability), success: {message: t("availability.create.success")}
    else
      flash.now[:alert] = {message: I18n.t("availability.create.error"),
                           options: {list_items: @availability.errors.full_messages}}
      render "create_fail", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /availabilities/1
  def update
    if @availability.update(availability_params)
      redirect_to availability_path(@availability), success: {message: I18n.t("availability.update.success")}
    else
      flash.now[:alert] = {message: I18n.t("availability.update.error"),
                           options: {list_items: @availability.errors.full_messages}}
      render "update_fail", status: :unprocessable_entity
    end
  end

  # DELETE /availabilities/1
  def destroy
    respond_to do |format|
      if @availability.destroy
        format.html { redirect_to availabilities_url, success: t("availability.destroy.success") }
        format.turbo_stream
      else
        format.html { redirect_to availabilities_url, alert: t("availability.destroy.error") }
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
