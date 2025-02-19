class Availability < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    against: [:name, :description],
    using: {tsearch: {prefix: true}}
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

  before_destroy :ensure_multiple_availabilities
  after_destroy :transfer_user_availability

  DEFAULT_PARAMS = {
    name: "New Availability",
    description: ""
  }.freeze

  def username
    user.username
  end

  private

  def transfer_user_availability
    fallback_availability = user.availabilities.where.not(id: id).first
    user_availability = User.find(user.id).user_availability
    if user_availability&.availability == self
      user_availability.update!(availability: fallback_availability)
    end
  end

  def ensure_multiple_availabilities
    if user.availabilities.count <= 1
      errors.add(:base, "Cannot delete your only availability")
      throw(:abort)
    end
  end
end
