require "test_helper"

class GroupTest < ActiveSupport::TestCase
  setup do
    @group = Group.create(name: "Test Group")
    @request = ActionDispatch::TestRequest.create
  end

  test "invite_url generates correct url" do
    expected_url = Rails.application.routes.url_helpers.join_invite_url(invite_token: @group.invite_token, host: @request.host)
    assert_equal expected_url, @group.invite_url(@request)
  end
end
