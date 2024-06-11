json.extract! proposal_vote, :id, :user_id, :proposal_id, :yes_vote, :comment, :created_at, :updated_at
json.url proposal_vote_url(proposal_vote, format: :json)
