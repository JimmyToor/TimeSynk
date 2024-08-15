json.extract! schedule, :id, :user_id, :start_date, :end_date, :duration, :schedule_pattern, :name
json.url schedule_url(schedule, format: :json)
