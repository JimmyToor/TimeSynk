json.extract! game_session_attendance, :id, :game_session_id, :user_id, :attending, :created_at, :updated_at
json.url game_session_attendance_url(game_session_attendance, format: :json)
