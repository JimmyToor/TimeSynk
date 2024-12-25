class Game < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search_name, against: :name, using: { tsearch: { prefix: true } }
  has_many :game_proposals, inverse_of: :game

  validates :name, presence: true
  validates :cover_image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  def self.get_popular
    @games = Game.where(is_popular: true)
  end

end
