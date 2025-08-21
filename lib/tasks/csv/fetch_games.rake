require "csv"

# Task to initialize the CSV with games from the IGDB API
namespace :csv do
  desc "Fetch games from IGDB to CSV"
  task fetch_games: :environment do
    file_path = "./db/seeds/games.csv"
    games = Gateways.game.fetch_all_games(fields: "id, slug, name, cover.url, platforms.name, first_release_date, created_at, updated_at")
    popular_game_ids = Gateways.game.fetch_popular_game_ids(limit: 100).each.map(&:game_id)

    games_to_insert = games.map do |game|
      {
        igdb_id: game.id,
        name: game.name || "N/A",
        release_date: game.first_release_date || nil,
        platforms: game.platforms&.each&.map(&:name) || [],
        cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
        igdb_url: "https://www.igdb.com/games/#{game.slug}",
        is_popular: popular_game_ids.include?(game.id),
        created_at: game.created_at ? Time.at(game.created_at).to_s : Time.current.to_s,
        updated_at: game.updated_at ? Time.at(game.updated_at).to_s : Time.current.to_s
      }
    end
    CSV.open(file_path, "wb") do |csv|
      # Add headers
      csv << %w[igdb_id name release_date platforms cover_image_url igdb_url is_popular created_at updated_at]

      # Fetch all games
      games_to_insert.each do |game|
        csv << [
          game[:igdb_id],
          game[:name],
          game[:release_date],
          game[:platforms]&.join(", ") || "TBA",
          game[:cover_image_url],
          game[:igdb_url],
          game[:is_popular],
          game[:created_at],
          game[:updated_at]
        ]
      end
    end

    puts "Exported games to CSV successfully to #{file_path}!"
  end
end
