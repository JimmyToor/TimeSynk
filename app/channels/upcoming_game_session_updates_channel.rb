class UpcomingGameSessionUpdatesChannel < ApplicationCable::Channel
  def subscribed
    return unless current_user.present?
    if params[:group_id].present? && params[:group_id] > 0
      group = Group.find(params[:group_id])
      raise Pundit::NotAuthorizedError unless GroupPolicy.new(current_user, group).show?
      stream_for group
    else
      current_user.groups.each do |group|
        stream_for group
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    logger.error "UpcomingGameSessionUpdatesChannel: Record not found - #{e.message}"
    reject
  rescue Pundit::NotAuthorizedError => e
    logger.error "UpcomingGameSessionUpdatesChannel: Not authorized - #{e.message}"
    reject
  end

  def unsubscribed
    stop_all_streams
  end
end
