class AvailabilitySchedule < ApplicationRecord
  belongs_to :availability
  belongs_to :schedule

  validates_associated :availability, :schedule
end
