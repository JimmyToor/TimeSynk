json.extract! group_membership, :id, :group_id, :user_id, :created_at, :updated_at
json.url group_membership_url(group_membership, format: :json)
