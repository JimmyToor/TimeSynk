require "date"

# One time task to initialize the database with games from the IGDB API
namespace :db do
  desc "Fetch games from IGDB API"
  task fetch_games: :environment do
    Rails.logger.tagged("InitialGamesAPIFetch") do
      Rails.logger.info "Starting initial game fetch..."
      puts "Starting initial game fetch..."

      games = Gateways.game.fetch_all_games(fields: "id, slug, name, cover.url, platforms.name, first_release_date, created_at, updated_at")
      popular_game_ids = Gateways.game.fetch_popular_game_ids(limit: 100).each.map(&:game_id)

      Game.transaction do
        games.each_slice(1000) do |batch|
          games_to_insert = batch.map do |game|
            {
              igdb_id: game.id,
              name: game.name || "N/A",
              release_date: game.first_release_date ? Time.at(game.first_release_date).utc.to_datetime : nil,
              platforms: game.platforms ? game.platforms.map(&:name) : [],
              cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
              igdb_url: "https://www.igdb.com/games/#{game.slug}",
              is_popular: popular_game_ids.include?(game.id),
              created_at: game.created_at ? Time.at(game.created_at) : Time.current.utc,
              updated_at: game.updated_at ? Time.at(game.updated_at) : Time.current.utc
            }
          end

          Game.upsert_all(games_to_insert, unique_by: :igdb_id)
          print "."  # Progress indicator
        rescue => e
          Rails.logger.error "Error batch inserting games: #{e.message}"
          puts "Error batch inserting games: #{e.message}"
        end
      end

      message = "Fetched and imported #{games.count} games successfully."
      Rails.logger.info message
      puts message
    rescue => e
      Rails.logger.error "Error fetching and importing games from API: #{e.message}"
      Rails.logger.error e.backtrace&.join("\n")
      puts "Error fetching and importing games from API: #{e.message}"
    end
  end
end
