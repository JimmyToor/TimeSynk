class Availability < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    against: [:name, :description],
    using: {tsearch: {prefix: true}}
  belongs_to :user
  has_many :availability_schedules, dependent: :destroy, inverse_of: :availability
  has_many :schedules, through: :availability_schedules
  has_one :user_availability, inverse_of: :availability
  has_many :group_availabilities, inverse_of: :availability, dependent: :destroy
  has_many :proposal_availabilities, inverse_of: :availability, dependent: :destroy

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.squish }

  validates :name, presence: true, length: {maximum: 300}, uniqueness: {scope: :user}
  validates :description, length: {maximum: 300}
  validates :user, presence: true

  before_destroy :transfer_user_availability

  DEFAULT_PARAMS = {
    name: "New Availability",
    description: ""
  }.freeze

  def username
    user.username
  end

  private

  def ensure_multiple_availabilities
    if user.availabilities.count <= 1
      errors.add(:base, I18n.t("availability.destroy.only_availability"))
      throw(:abort)
    end
  end

  def transfer_user_availability
    return unless user_availability.present?
    ensure_multiple_availabilities
    fallback_availability = user.availabilities.where.not(id: id).first
    user_availability = user.user_availability
    user_availability.update!(availability: fallback_availability)
  end
end
