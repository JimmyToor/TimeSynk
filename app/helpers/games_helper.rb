# Module: GamesHelper
#
# A helper module that provides methods for handling the display of
# game-related data, including game art and names.
module GamesHelper
  # Displays a game artwork, name, or both within a styled container.
  # @param game [Game] The game object to display.
  # @param only_art [Boolean] If true, only the game artwork will be displayed. Default is false.
  # @param only_name [Boolean] If true, only the game name will be displayed. Default is false.
  # @param img_size [String] The size of the game artwork to display. Default is GameImageSize::THUMB.
  # @param fig_classes [String] Additional CSS classes for the container div. Default is an empty string.
  # @param img_classes [String] Additional CSS classes for the game art or name. Default is an empty string.
  # @param image_options [GameImageSize] Additional options to pass to the `image_tag` helper for the game artwork.
  # @return [String] The HTML-safe string generated for the game display.
  def display_game_art_and_name(game:, only_art: false, only_name: false, img_size: GameImageSize::THUMB, fig_classes: "", img_classes: "", **image_options)
    content_tag(:figure, class: "game-display #{fig_classes}") do
      unless only_name
        url = if game.cover_image_url.present?
          game.cover_image_url
        else
          Game::NO_COVER_URL
        end
        concat image_tag(url.sub("thumb", img_size),
          alt: game.name,
          class: "game-art #{img_classes}",
          id: dom_id(game, :art),
          data: {proposal_selection_target: "gameArt"},
          **image_options)
      end
      unless only_art
        concat content_tag(:figcaption,
          game.name,
          class: "game-name text-wrap",
          data: {proposal_selection_target: "gameName"},
          id: dom_id(game, :name))
      end
    end
  end

  #   def display_icon_for_platform(platform:, size: 32)
  #     icon = case platform
  #     when "steam"
  #       "fab fa-steam"
  #     when "playstation"
  #       "fab fa-playstation"
  #     when "xbox"
  #       "fab fa-xbox"
  #     when "nintendo"
  #       "fab fa-nintendo-switch"
  #     else
  #       "fas fa-gamepad"
  #            end
  #     image_tag(platform.icon_url, alt: platform.name, class: "platform-icon", style: "width: #{size}px; height: #{size}px;")
  #   end
end
