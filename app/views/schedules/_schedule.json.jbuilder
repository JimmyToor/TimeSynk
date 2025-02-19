json.extract! schedule, :id, :user_id, :start_time, :end_time, :duration, :schedule_pattern, :name
json.url schedule_url(schedule, format: :json)
