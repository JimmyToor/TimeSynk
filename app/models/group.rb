class Group < ApplicationRecord
  include Restrictable
  resourcify
  restrict(min_weight: RoleHierarchy::ROLE_WEIGHTS[:"group.admin"])

  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :game_proposals, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
  has_many :invites, dependent: :destroy

  scope :for_user, ->(user) { joins(:group_memberships).where(group_memberships: {user_id: user.id}) }

  normalizes :name, with: ->(name) { name.squish }

  validates :name,
    presence: {message: I18n.t("group.validation.name.presence")},
    length: {maximum: 50, message: I18n.t("group.validation.name.length", count: 50)}

  def reload(options = nil)
    @owner = nil
    super
  end

  def get_user_group_availability(user)
    group_availabilities.find_by(user: user)
  end

  def associated_users
    users
  end

  def associated_users_without_owner
    users.where.not(id: owner.id)
  end

  def owner
    @owner ||= User.with_role(:owner, self).first
  end

  def is_user_member?(user)
    users.exists?(id: user.id)
  end

  def membership_for_user(user)
    group_memberships.find_by(user: user)
  end

  def create_roles
    Role.create_roles_for_group(self)
  end

  def members
    group_memberships.includes(:user).map(&:user)
  end

  def notify_calendar_update(cascade = true)
    CalendarUpdateNotifierService.call(self, cascade)
  end

  def game_proposals_user_can_create_sessions_for(user)
    game_proposals.includes(:group).select do |proposal|
      Pundit.policy(user, proposal).create_game_session?
    end
  end
end
