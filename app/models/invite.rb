class Invite < ApplicationRecord
  resourcify

  belongs_to :user
  belongs_to :group
  has_secure_token :invite_token

  validate :validate_roles
  attr_readonly :user_id, :group_id

  def assigned_roles
    Role.where(id: assigned_role_ids)
  end

  def assigned_roles=(roles)
    self.assigned_role_ids = roles.map(&:id)
  end

  # Determines which roles the user can assign to the invitee.
  # Users who are not admins or higher in the group cannot assign any roles.
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

  private

  def validate_roles
    assigned_role_ids.each do |role_id|
      if role_id.is_a?(Integer) && !Role.find_by(id: role_id)
        errors.add(:assigned_role_ids, "Role #{role_id} not found")
      end
    end
  end

  scope :for_group, ->(group_id) { where(group: group_id) }
end
