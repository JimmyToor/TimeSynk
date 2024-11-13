class GroupMembership < ApplicationRecord
  resourcify

  belongs_to :group
  belongs_to :user

  validates_associated :group, :user
  validates :group, uniqueness: { scope: :user, message: I18n.t("group_membership.already_member") }
end
