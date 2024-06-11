json.extract! schedule, :id, :start_date, :end_date, :duration, :schedule_pattern, :created_at, :updated_at
json.url schedule_url(schedule, format: :json)
