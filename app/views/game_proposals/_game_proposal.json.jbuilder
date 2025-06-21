json.extract! game_proposal, :id, :group_id, :game_id, :yes_votes_count, :no_votes_count, :created_at, :updated_at
json.set! :group_name, game_proposal.group.name
json.url game_proposal_url(game_proposal, format: :json)
