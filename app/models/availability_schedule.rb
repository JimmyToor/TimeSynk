class AvailabilitySchedule < ApplicationRecord
  belongs_to :availability
  belongs_to :schedule

  # Don't bother with validations if the associated object is failing to be created
  validates_associated :availability, unless: ->(availability_schedule) {
    availability = availability_schedule.availability
    availability&.new_record? && !availability.valid?
  }
  validates_associated :schedule, unless: ->(availability_schedule) {
    schedule = availability_schedule.schedule
    schedule&.new_record? && !schedule.valid?
  }
end
