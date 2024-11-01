class Invite < ApplicationRecord
  resourcify

  belongs_to :user
  belongs_to :group
  has_secure_token :invite_token

  def assigned_roles
    Role.where(id: assigned_role_ids)
  end

  def assigned_roles=(roles)
    self.assigned_role_ids = roles.map(&:id)
  end

  scope :for_group, ->(group_id) { where(group: group_id) }

end