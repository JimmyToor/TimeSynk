require "application_system_test_case"

class GamesTest < ApplicationSystemTestCase
  setup do
    @game = games(:thief)
  end

  test "visiting the index" do
    visit games_url
    assert_selector "h1", text: "Games"
  end
end
