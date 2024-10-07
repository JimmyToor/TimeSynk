module GamesHelper
  def display_game_art_and_name(game)
    content_tag(:div, class: 'game-display') do
      concat content_tag(:div, image_tag(game.cover_image_url, alt: game.name, class: 'game-art'), id: dom_id(game, :art))
      concat content_tag(:div, content_tag(:p, game.name, class: 'game-name'), id: dom_id(game, :name))
    end
  end
end
