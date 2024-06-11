class Group < ApplicationRecord
  has_many :users, through: :group_memberships
  has_many :group_memberships, dependent: :destroy
  has_many :game_proposals, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
end
