class Availability < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
                  against: [:name, :description],
                  using: { tsearch: { prefix: true } }
  belongs_to :user
  has_many :availability_schedules, dependent: :destroy, inverse_of: :availability
  has_many :schedules, through: :availability_schedules
  has_one :user_availability, inverse_of: :availability, dependent: :destroy
  has_many :group_availabilities, inverse_of: :availability, dependent: :destroy
  has_many :proposal_availabilities, inverse_of: :availability, dependent: :destroy

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, length: {maximum: 300}, uniqueness: {scope: :user}
  validates :description, length: {maximum: 300}
  validates :user, presence: true

  DEFAULT_PARAMS = {
    name: "Default Availability",
    description: ""
  }.freeze

  def username
    user.username
  end
end
