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
end
