class UserAvailability < ApplicationRecord
  belongs_to :availability, inverse_of: :user_availability
  belongs_to :user, inverse_of: :user_availability
  has_many :availability_schedules, through: :availability, dependent: :destroy
  has_many :schedules, through: :availability_schedules

  validates :user, presence: true, uniqueness: true

  scope :for_user, ->(user) { where(user: user) }
end
