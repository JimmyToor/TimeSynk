require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:thief_2)
    @user = users(:cooluserguy)
    sign_in_as @user
  end

  test "should get index" do
    get games_url
    assert_response :success
  end
end
