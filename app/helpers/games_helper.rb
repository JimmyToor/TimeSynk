module GamesHelper
  def display_game_art_and_name(game)
    content_tag(:div, class: 'game-display') do
      concat content_tag(:div, image_tag(game.cover_image_url, alt: game.name, class: 'game-art', id: dom_id(game, :art), data: {proposal_selection_target:"gameArt"}))
      concat content_tag(:div, content_tag(:h3, game.name, class: 'game-name', data: {proposal_selection_target:"gameName"}), id: dom_id(game, :name) )
    end
  end
end
