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
      group.roles.reject { |role| role.name == "owner" }
    else
      []
    end
  end

  def self.with_token(token)
    find_by(invite_token: token)
  end

  def user_can_change_roles(role_ids)
    return Invite.available_roles(user, group).pluck(:id).include?(role_ids) if user.present?
    false
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
