# frozen_string_literal: true

# Broadcasts notifications when a resource affecting calendar views is updated.
#
# @example Notify relevant parties after a GameSession is updated
#   game_session = GameSession.find(params[:id])
#   if game_session.update(game_session_params)
#     CalendarUpdateNotifierService.call(game_session)
#   end
class CalendarUpdateNotifierService < ApplicationService
  # Initializes the service with the resource that triggered the notification.
  #
  # @param resource [GameSession] The updated resource instance (currently supports GameSession).
  def initialize(resource, cascade = true)
    @resource = resource
    @cascade = cascade
  end

  # Executes the notification logic based on the resource type.
  #
  # @return [void]
  def call
    if @resource.is_a?(GameSession)
      previous_date = @resource.date_before_last_save
      dates = [@resource.date]
      dates << previous_date if previous_date.present?
      notify_game_proposal(@resource.game_proposal.id, dates)
      return unless @cascade
      notify_group(@resource.game_proposal.group.id, dates)
      notify_group_users(@resource.game_proposal.group, dates)
    elsif @resource.is_a?(GameProposal)
      notify_game_proposal(@resource.id)
      return unless @cascade
      notify_group(@resource.group.id, [])
      notify_group_users(@resource.group, [])
    elsif @resource.is_a?(Group)
      notify_group(@resource.id, [])
      return unless @cascade
      notify_group_users(@resource, [])
    else
      raise ArgumentError, "Unsupported resource type: #{@resource.class.name}"
    end
  end

  private

  # Broadcasts a calendar update notification to a specific group channel.
  #
  # @param id [Integer] The ID of the group.
  # @param dates [Array<Date>] Optional array of specific dates that were affected.
  # @return [void]
  def notify_group(id, dates = [])
    Calendar.broadcast_calendar_update_notification("group_#{id}", {dates: dates})
  end

  # Broadcasts a calendar update notification to a specific game proposal channel.
  #
  # @param id [Integer] The ID of the game proposal.
  # @param dates [Array<Date>] Optional array of specific dates that were affected.
  # @return [void]
  def notify_game_proposal(id, dates = [])
    Calendar.broadcast_calendar_update_notification("game_proposal_#{id}", {dates: dates})
  end

  # Broadcasts a calendar update notification to the channels of all users within a group.
  #
  # @param group [Group] The group whose users should be notified.
  # @param dates [Array<Date>] Optional array of specific dates that were affected.
  # @return [void]
  def notify_group_users(group, dates = [])
    group.users.each do |user|
      Calendar.broadcast_calendar_update_notification("user_#{user.id}", {dates: dates})
    end
  end
end
