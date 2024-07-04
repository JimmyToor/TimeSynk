class Group < ApplicationRecord
  resourcify

  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :game_proposals, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
  has_many :invites, dependent: :destroy

  scope :for_user , ->(user) { joins(:group_memberships).where(group_memberships: { user_id: user.id }) }

  validates :name, presence: true
end
