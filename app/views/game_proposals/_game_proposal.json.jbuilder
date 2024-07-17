json.extract! game_proposal, :id, :group_id, :game_id, :user_id, :yes_votes, :no_votes, :created_at, :updated_at
json.url game_proposal_url(game_proposal, format: :json)
