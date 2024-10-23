json.extract! game, :id, :igdb_id, :name, :cover_image_url, :platform, :igdb_url, :release_date, :created_at, :updated_at
json.url game_url(game, format: :json)
