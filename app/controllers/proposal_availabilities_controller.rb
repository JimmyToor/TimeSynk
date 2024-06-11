class ProposalAvailabilitiesController < ApplicationController
  before_action :set_proposal_availability, only: %i[ show edit update destroy ]

  # GET /proposal_availabilities or /proposal_availabilities.json
  def index
    @proposal_availabilities = ProposalAvailability.all
  end

  # GET /proposal_availabilities/1 or /proposal_availabilities/1.json
  def show
  end

  # GET /proposal_availabilities/new
  def new
    @proposal_availability = ProposalAvailability.new
  end

  # GET /proposal_availabilities/1/edit
  def edit
  end

  # POST /proposal_availabilities or /proposal_availabilities.json
  def create
    @proposal_availability = ProposalAvailability.new(proposal_availability_params)

    respond_to do |format|
      if @proposal_availability.save
        format.html { redirect_to proposal_availability_url(@proposal_availability), notice: "Proposal availability was successfully created." }
        format.json { render :show, status: :created, location: @proposal_availability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @proposal_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /proposal_availabilities/1 or /proposal_availabilities/1.json
  def update
    respond_to do |format|
      if @proposal_availability.update(proposal_availability_params)
        format.html { redirect_to proposal_availability_url(@proposal_availability), notice: "Proposal availability was successfully updated." }
        format.json { render :show, status: :ok, location: @proposal_availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @proposal_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /proposal_availabilities/1 or /proposal_availabilities/1.json
  def destroy
    @proposal_availability.destroy!

    respond_to do |format|
      format.html { redirect_to proposal_availabilities_url, notice: "Proposal availability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proposal_availability
      @proposal_availability = ProposalAvailability.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def proposal_availability_params
      params.require(:proposal_availability).permit(:schedule_id, :user_id, :proposal_id)
    end
end
