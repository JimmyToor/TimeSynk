class Game < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search_name, against: :name, using: {tsearch: {prefix: true}}
  has_many :game_proposals, inverse_of: :game

  validates :name, presence: true
  validates :cover_image_url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true}

  NO_COVER_URL = "https://images.igdb.com/igdb/image/upload/t_thumb/nocover.png"

  def self.get_popular
    @games = Game.where(is_popular: true)
  end

  # Sets the image size for the cover image URL. Does not persist.
  #
  # @param size [GameImageSize] The desired image size.
  def set_image_size(size)
    if GameImageSize.include?(size)
      self.cover_image_url = cover_image_url.sub("thumb", GameImageSize.const_get(size))
    else
      errors.add(:cover_image_url, "Invalid image size")
    end
  end

  def display_html(game, only_art: false, img_size: GameImageSize::THUMB, img_classes: "")
    helpers.display_game_art_and_name(game: game, only_art: only_art, img_size: img_size, img_classes: img_classes)
  end
end
