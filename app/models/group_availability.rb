class GroupAvailability < ApplicationRecord
  belongs_to :schedule, dependent: :destroy
  belongs_to :user
  belongs_to :group
end
