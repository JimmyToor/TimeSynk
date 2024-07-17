json.extract! game_session, :id, :user_id, :game_proposal_id, :date, :duration, :created_at, :updated_at
json.url game_session_url(game_session, format: :json)
