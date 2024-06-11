json.extract! user_availability, :id, :schedule_id, :user_id, :created_at, :updated_at
json.url user_availability_url(user_availability, format: :json)
