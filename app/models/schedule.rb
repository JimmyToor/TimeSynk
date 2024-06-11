class Schedule < ApplicationRecord
  has_one :user_availability, dependent: :destroy
  has_one :group_avalability, dependent: :destroy
  has_one :proposal_availabily, dependent: :destroy
  
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :start_time, timeliness: {on_or_before: :end_time, type: :datetime}
  validates :end_time, timeliness: {on_or_after: :start_time, type: :datetime}
end
