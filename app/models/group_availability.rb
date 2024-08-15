class GroupAvailability < ApplicationRecord
  belongs_to :availability
  belongs_to :group
  belongs_to :user
  has_many :availability_schedules, through: :availability
  has_many :schedules, through: :availability_schedules

  validates :user, uniqueness: {scope: :group}

  scope :for_group, ->(group) { where(group: group) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_user_and_group, ->(user, group) { where(user: user, group: group) }
end