require "test_helper"

class UpdatePendingCountBroadcastJobTest < ActiveJob::TestCase
  test "broadcasts update with expected stream, target, partial, and locals" do
    user_id = 42
    count = 3
    calls = []

    Turbo::StreamsChannel.stub(:broadcast_update_to, ->(stream, target:, partial:, locals:) do
      calls << {stream: stream, target: target, partial: partial, locals: locals}
    end) do
      GameProposals::UpdatePendingCountBroadcastJob.perform_now(user_id, count: count)
    end

    assert_equal 1, calls.size
    call = calls.first
    assert_equal "pending_game_proposals_count_user_#{user_id}", call[:stream]
    assert_equal "pending_game_proposals_count", call[:target]
    assert_equal "game_proposals/pending_count", call[:partial]
    assert_equal({count: count}, call[:locals])
  end
end
