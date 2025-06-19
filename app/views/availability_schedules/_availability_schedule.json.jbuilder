json.extract! availability_schedule, :id, :availability_id, :schedule_id, :created_at, :updated_at

json.availability do
  json.merge! availability_schedule.availability.attributes
end

json.schedule do
  json.merge! availability_schedule.schedule.attributes
end
