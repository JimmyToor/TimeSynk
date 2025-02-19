class Group < ApplicationRecord
  include Permissionable
  resourcify

  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :game_proposals, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
  has_many :invites, dependent: :destroy

  scope :for_user, ->(user) { joins(:group_memberships).where(group_memberships: {user_id: user.id}) }

  validates :name, presence: true, length: {maximum: 50}

  def get_user_group_availability(user)
    group_availabilities.find_by(user: user)
  end

  def is_user_member?(user)
    users.include?(user)
  end

  def membership_for_user(user)
    group_memberships.find_by(user: user)
  end

  def create_roles
    Role.create_roles_for_group(self)
  end

  def owner
    User.with_role(:owner, self).first
  end
end
