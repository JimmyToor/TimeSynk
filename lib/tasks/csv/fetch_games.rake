require "csv"

namespace :csv do
  desc "Fetch games from IGDB to CSV"
  task fetch_games: :environment do
    file_path = "./db/seeds/games.csv"
    games = Gateways.game.fetch_all_games(fields: "id, slug, name, cover.url, platforms.name, first_release_date")

    games_to_insert = games.map do |game|
      {
        igdb_id:         game.id,
        name:            game.name || "N/A",
        release_date:    game.first_release_date || nil,
        platforms:       game.platforms&.each&.map(&:name) || [],
        cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
        igdb_url:        "https://www.igdb.com/games/#{game.slug}",
        created_at:      Time.current,
        updated_at:      Time.current
      }
    end
    CSV.open(file_path, "wb") do |csv|
      # Add headers
      csv << %w[igdb_id name release_date platforms cover_image_url igdb_url is_popular created_at updated_at]

      # Fetch all games
      games_to_insert.each do |game|
        csv << [
          game[:igdb_id],
          game[:name] || "N/A",
          game[:release_date],
          game[:platforms]&.join(", ") || "",
          game[:cover_image_url],
          game[:igdb_url],
          false,
          game[:created_at],
          game[:updated_at]
        ]
      end
    end

    puts "Exported games to CSV successfully to #{file_path}!"
  end
end
