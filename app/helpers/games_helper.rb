module GamesHelper
  def display_game_art_and_name(game:, only_art: false, only_name: false, classes: "", **image_options)
    content_tag(:div, class: "game-display #{classes}") do
      unless only_name
        concat image_tag(game.cover_image_url,
          alt: game.name,
          class: "game-art",
          id: dom_id(game, :art),
          data: {proposal_selection_target: "gameArt"},
          **image_options)
      end
      unless only_art
        concat content_tag(:h3,
          game.name,
          class: "game-name",
          data: {proposal_selection_target:"gameName"},
          id: dom_id(game, :name))
      end
    end
  end

=begin
  def display_icon_for_platform(platform:, size: 32)
    icon = case platform
    when "steam"
      "fab fa-steam"
    when "playstation"
      "fab fa-playstation"
    when "xbox"
      "fab fa-xbox"
    when "nintendo"
      "fab fa-nintendo-switch"
    else
      "fas fa-gamepad"
           end
    image_tag(platform.icon_url, alt: platform.name, class: "platform-icon", style: "width: #{size}px; height: #{size}px;")
  end
=end
end
