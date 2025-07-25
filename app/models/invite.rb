class Invite < ApplicationRecord
  resourcify

  belongs_to :user
  belongs_to :group
  has_secure_token :invite_token

  normalizes :assigned_role_ids, with: ->(role_ids) {
    role_ids.reject(&:blank?).map(&:to_i).uniq
  }

  validate :validate_roles, :validate_date
  attr_readonly :user_id, :group_id

  scope :for_group, ->(group_id) { where(group: group_id) }
  scope :expired, -> { where("expires_at < ?", Time.current) }

  def assigned_roles
    Role.where(id: assigned_role_ids)
  end

  def assigned_roles=(roles)
    self.assigned_role_ids = roles.map(&:id)
  end

  # Determines which roles the user can assign to the invitee.
  # Users who are not admins or higher in the group cannot assign any invite roles.
  #
  # @param user [User] the user who is creating/editing the invite
  # @param group [Group] the group the invite is for
  # @return [Array<Role>] the roles the user can assign
  def self.available_roles(user, group)
    admin_weight = RoleHierarchy.role_weight(Role.find_by(resource: group, name: "admin"))
    if user.most_permissive_role_weight_for_resource(group) < admin_weight
      group.roles.reject { |role| RoleHierarchy.special?(role) }
    else
      []
    end
  end

  # Finds an invite by its token.
  # @param token [String] the invite token to search for
  # @param scope [ActiveRecord::Relation] the scope to search within, defaults to all invites
  # @return [Invite, nil] the invite if found, otherwise nil
  def self.with_token(token, invite_scope: Invite.all)
    invite_scope.find_by(invite_token: token)
  end

  def user_can_change_roles?(role_ids)
    return (role_ids - Invite.available_roles(user, group).pluck(:id)).empty? if user.present?
    false
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def self.destroy_expired_invites
    expired.destroy_all
  end

  # Finds the invite associated with the given token.
  # @return [Invite] the invite if found, otherwise a new Invite with an appropriate error.
  def self.from_token(token)
    invite = Invite.with_token(token)

    if invite.nil?
      invite = Invite.new(invite_token: token)
      invite.errors.add(:base, I18n.t("invite.invalid"))
    elsif invite.expired?
      invite.errors.add(:base, I18n.t("invite.expired"))
    end

    invite
  end

  private

  def validate_roles
    valid_roles = Role.where(resource: group).pluck(:id)

    assigned_role_ids.each do |role_id|
      if !role_id.is_a?(Integer) || !Role.find_by(id: role_id) || !valid_roles.include?(role_id)
        errors.add(:assigned_role_ids, I18n.t("invite.validation.assigned_role_ids.invalid"))
        break
      end
    end
  end

  def validate_date
    if expires_at.nil?
      self.expires_at = 1.week.from_now
    end
  end
end
