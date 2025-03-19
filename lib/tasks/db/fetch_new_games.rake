require "date"

# Repeatable task to fetch new games from the IGDB API
namespace :db do
  desc "Fetch new games from IGDB API"
  task fetch_new_games: :environment do
    Rails.logger.tagged("NewGamesAPIFetch") do
      Rails.logger.info "Starting new games fetch..."
      puts "Starting new games fetch..."

      new_games = Gateways.game.fetch_all_new_games(fields: "id, slug, name, cover.url, platforms.name, first_release_date, created_at, updated_at")

      Game.transaction do
        new_games.each_slice(1000) do |batch|
          games_to_insert = batch.map do |game|
            {
              igdb_id: game.id,
              name: game.name || "N/A",
              release_date: game.first_release_date || nil,
              platforms: game.platforms ? game.platforms.map(&:name) : [],
              cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
              igdb_url: "https://www.igdb.com/games/#{game.slug}",
              is_popular: false,
              created_at: game.created_at ? Time.at(game.created_at).utc : Time.current.utc,
              updated_at: game.updated_at ? Time.at(game.updated_at).utc : Time.current.utc
            }
          end

          Game.upsert_all(games_to_insert, unique_by: :igdb_id)
          print "."  # Progress indicator
        rescue => e
          Rails.logger.error "Error batch inserting new games: #{e.message}"
          puts "Error batch inserting new games: #{e.message}"
        end
      end

      message = "Fetched and imported #{new_games.count} new games successfully."
      Rails.logger.info message
      puts message
    rescue => e
      Rails.logger.error "Error fetching and importing new games from API: #{e.message}"
      Rails.logger.error e.backtrace&.join("\n")
      puts "Error fetching and importing new games from API: #{e.message}"
    end
  end
end
