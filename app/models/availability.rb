class Availability < ApplicationRecord
  belongs_to :user
  has_many :availability_schedules, dependent: :destroy, inverse_of: :availability
  has_many :schedules, through: :availability_schedules
  has_one :user_availability, inverse_of: :availability, dependent: :destroy
  has_many :group_availabilities, inverse_of: :availability, dependent: :destroy
  has_many :proposal_availabilities, inverse_of: :availability, dependent: :destroy

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: {scope: :user}
  validates :user, presence: true

  def username
    user.username
  end
end
