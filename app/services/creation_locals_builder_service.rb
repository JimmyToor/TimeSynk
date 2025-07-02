# frozen_string_literal: true

# This service builds the locals for the rendering of a creation modal
#
# Inherits from ApplicationService.
#
# @example Building locals for a creation modal
#   params = ActionController::Parameters.new(date: '2023-10-01', game_proposal_id: 1).permit(:date, :game_proposal_id, :group_id, :user_id)
#   locals = CreationLocalsBuilderService.call(params, Current.user)
#   # locals will contain the necessary data for rendering the creation modal
#
class CreationLocalsBuilderService < ApplicationService
  def initialize(params, user)
    @params = params
    @user = user
  end

  def call
    build_locals
  end

  def build_locals
    locals = {}
    locals[:schedule] = Schedule.new_default(@user.id)
    locals[:date] = @params[:date].present? ? Date.parse(@params[:date]) : Date.today

    if @params[:game_proposal_id].present?
      build_game_proposal_locals(locals)
    elsif @params[:group_id].present?
      build_group_locals(locals)
    elsif @params[:user_id].present?
      build_user_locals(locals)
    end

    locals
  end

  private

  def build_game_proposal_locals(locals)
    game_proposal = GameProposal.find(@params[:game_proposal_id])
    if GameProposalPolicy.new(@user, game_proposal).create_game_session?
      locals[:initial_game_proposal] = game_proposal
    end
  end

  def build_group_locals(locals)
    group = Group.find(@params[:group_id])
    if group.game_proposals.any?
      game_proposals = group.game_proposals_user_can_create_sessions_for(@user)
      locals[:game_proposals] = game_proposals
      locals[:initial_game_proposal] = game_proposals.first
    end
  end

  def build_user_locals(locals)
    user = User.find(@params[:user_id])
    game_proposals = user.game_proposals_user_can_create_sessions_for

    if game_proposals.any?
      locals[:groups] = game_proposals.map(&:group).uniq
      locals[:initial_game_proposal] = game_proposals.first
    end
  end
end
