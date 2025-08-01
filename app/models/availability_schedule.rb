class AvailabilitySchedule < ApplicationRecord
  belongs_to :availability
  belongs_to :schedule
end
