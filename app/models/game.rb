class Game < ApplicationRecord
  has_many :game_proposals, inverse_of: :game

  validates :name, presence: true
  validates :cover_image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  def self.get_popular
    # Placeholder implementation without caching
    @popular_game_ids = Gateways.game.get_popular_game_ids.each.map(&:game_id)
    @games = Game.where(igdb_id: @popular_game_ids)
  end

end
