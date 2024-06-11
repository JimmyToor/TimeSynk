class GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[ show edit update destroy ]

  # GET /group_memberships or /group_memberships.json
  def index
    @group_memberships = GroupMembership.all
  end

  # GET /group_memberships/1 or /group_memberships/1.json
  def show
  end

  # GET /group_memberships/new
  def new
    @group_membership = GroupMembership.new
  end

  # GET /group_memberships/1/edit
  def edit
  end

  # POST /group_memberships or /group_memberships.json
  def create
    @group_membership = GroupMembership.new(group_membership_params)

    respond_to do |format|
      if @group_membership.save
        format.html { redirect_to group_membership_url(@group_membership), notice: "Group membership was successfully created." }
        format.json { render :show, status: :created, location: @group_membership }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /group_memberships/1 or /group_memberships/1.json
  def update
    respond_to do |format|
      if @group_membership.update(group_membership_params)
        format.html { redirect_to group_membership_url(@group_membership), notice: "Group membership was successfully updated." }
        format.json { render :show, status: :ok, location: @group_membership }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_memberships/1 or /group_memberships/1.json
  def destroy
    @group_membership.destroy!

    respond_to do |format|
      format.html { redirect_to group_memberships_url, notice: "Group membership was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group_membership
      @group_membership = GroupMembership.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_membership_params
      params.require(:group_membership).permit(:group_id, :user_id)
    end
end
