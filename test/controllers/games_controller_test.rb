require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:thief)
    @user = users(:cooluserguy)
    sign_in_as @user
  end

  test "should get index" do
    get games_url
    assert_response :success
  end

  test "should get index with search query" do
    get games_url, params: {query: "Thief"}
    assert_response :success
  end

  test "should get index with turbo stream format" do
    get games_url, as: :turbo_stream
    assert_response :success
  end

  test "should show game" do
    get game_url(@game)
    assert_response :success
  end

  test "should show game with turbo stream format" do
    get game_url(@game), as: :turbo_stream
    assert_response :success
  end

  test "should show game with json format" do
    get game_url(@game), as: :json
    assert_response :success
    assert_equal @game.to_json, response.body
  end
end
