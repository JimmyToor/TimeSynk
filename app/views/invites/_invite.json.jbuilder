json.extract! invite, :id, :user_id, :group_id, :invite_token, :assigned_role_ids, :expires_at, :created_at, :updated_at
json.url invite_url(invite, format: :json)
