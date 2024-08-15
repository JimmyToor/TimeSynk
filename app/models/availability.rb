class Availability < ApplicationRecord
  belongs_to :user
  has_many :availability_schedules, dependent: :destroy
  has_many :schedules, through: :availability_schedules
  has_one :user_availability, inverse_of: :availability, dependent: :destroy
  has_one :group_availability, inverse_of: :availability, dependent: :destroy
  has_one :proposal_availability, inverse_of: :availability, dependent: :destroy

  validates :name, presence: true, uniqueness: {scope: :user}
  validates :user, presence: true
end
