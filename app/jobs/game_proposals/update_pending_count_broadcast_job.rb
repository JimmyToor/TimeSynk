# frozen_string_literal: true

module GameProposals
  class UpdatePendingCountBroadcastJob < ApplicationJob
    queue_as :default

    def perform(user_id, count:)
      Turbo::StreamsChannel.broadcast_update_to(
        "pending_game_proposals_count_user_#{user_id}",
        target: "pending_game_proposals_count",
        partial: "game_proposals/pending_count",
        locals: {count: count}
      )
    end
  end
end
