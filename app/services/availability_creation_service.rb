# frozen_string_literal: true

class AvailabilityCreationService
  def initialize(params, user, schedule_ids)
    @params = params.permit(:name)
    @user = user
    @schedule_ids = schedule_ids
  end

  # Creates a new [UserAvailability] and associated schedule.
  #
  # @return the newly created [UserAvailability].
  def create_availability
    ActiveRecord::Base.transaction do
      @schedules = Schedule.find(id: @schedule_ids)
      raise ActiveRecord::RecordNotFound, "No schedules found with the provided IDs." if @schedules.empty?
      @availability = @user.availabilities.build(@params)

      @availability.schedules << @schedules
    end
    @availability
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    @availability = Availability.build(@params)
    @availability.errors.add(:base, e.message)
    @availability
  end
end
