# frozen_string_literal: true

class OwnershipsController < ApplicationController
  add_flash_types :success, :error
  before_action :set_resource, only: [:update]

  def update
    authorize(@resource, policy_class: helpers.policy_class_for_resource(@resource))
    new_owner = User.find(params[:new_owner_id])

    if TransferOwnershipService.call(new_owner, @resource)
      flash[:success] = {message: t("ownership.update.success", new_owner: new_owner.username)}
    else
      flash[:error] = {message: t("ownership.update.error") + " #{t("generic.refresh_try_again")}"}
    end

    respond_to do |format|
      format.turbo_stream {
        redirect_to @resource, success: {message: I18n.t("ownership.update.success", new_owner: new_owner.username)}
      }
    end
  end

  private

  def set_resource
    if params.key?(:group_id)
      @resource = Group.find(params[:group_id])
    elsif params.key?(:game_proposal_id)
      @resource = GameProposal.find(params[:game_proposal_id])
    elsif params.key?(:game_session_id)
      @resource = GameSession.find(params[:game_session_id])
    else
      raise ActionController::ParameterMissing.new("No resource specified")
    end
  end
end
