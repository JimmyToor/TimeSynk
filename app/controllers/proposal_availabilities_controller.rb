class ProposalAvailabilitiesController < ApplicationController
  add_flash_types :success
  before_action :set_proposal_availability, only: %i[show edit update destroy]
  before_action :set_game_proposal, only: %i[new create]
  before_action :set_availabilities, only: %i[new edit create]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /proposal_availabilities or /proposal_availabilities.json
  def index
    @proposal_availabilities = ProposalAvailability.all
  end

  # GET /proposal_availabilities/1 or /proposal_availabilities/1.json
  def show
  end

  # GET /proposal_availabilities/new
  def new
    if @game_proposal.proposal_availabilities.where(user_id: Current.user.id).exists?
      redirect_to edit_proposal_availability_path(@game_proposal.proposal_availabilities.find_by(user_id: Current.user.id))
    end
    @proposal_availability = @game_proposal.proposal_availabilities.build(user_id: Current.user.id, game_proposal_id: params[:game_proposal_id])
  end

  # GET /proposal_availabilities/1/edit
  def edit
  end

  # POST /proposal_availabilities or /proposal_availabilities.json
  def create
    @availability = Availability.find_by!(id: proposal_availability_params[:availability_id])
    @proposal_availability = @game_proposal.proposal_availabilities.build(proposal_availability_params)

    respond_to do |format|
      if @proposal_availability.save
        format.html {
          redirect_to @game_proposal,
            success: {message: I18n.t("proposal_availability.create.success", game_name: @game_proposal.game_name),
                      options: {highlight: @game_proposal.game_name}}
        }
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
        format.html {
          redirect_to @proposal_availability.game_proposal,
            success: {message: I18n.t("proposal_availability.update.success", game_name: @proposal_availability.game_proposal.game_name),
                      options: {highlight: "#{@proposal_availability.game_proposal.game_name}."}}
        }
        format.json { render :show, status: :ok, location: @proposal_availability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @proposal_availability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /proposal_availabilities/1 or /proposal_availabilities/1.json
  def destroy
    game_proposal = @proposal_availability.game_proposal
    @proposal_availability.destroy!

    respond_to do |format|
      format.html {
        redirect_to game_proposal, success: {message: I18n.t("proposal_availability.destroy.success", game_name: @proposal_availability.game_proposal.game_name),
                                             options: {highlight: "#{@proposal_availability.game_proposal.game_name}."}}
      }
      format.json { head :no_content }
    end
  end

  private

  def set_proposal_availability
    @proposal_availability = ProposalAvailability.find(params[:id])
  end

  def set_game_proposal
    @game_proposal = GameProposal.find(params[:game_proposal_id])
  end

  def set_availabilities
    @availabilities = policy_scope(Availability)
  end

  # Only allow a list of trusted parameters through.
  def proposal_availability_params
    params.require(:proposal_availability).permit(:availability_id, :user_id, :game_proposal_id)
  end
end
