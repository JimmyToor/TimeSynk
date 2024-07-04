class Invite < ApplicationRecord
  resourcify

  belongs_to :user
  belongs_to :group
  has_secure_token :invite_token

  scope :for_group, ->(group_id) { where(group: group_id) }
end
