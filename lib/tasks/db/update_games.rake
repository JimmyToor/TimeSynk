require "date"

# Repeatable task to update the games in the database from the IGDB API
namespace :db do
  desc "Update games in db, only changing records that need updates"
  task update_games: :environment do
    Rails.logger.tagged("GamesAPIUpdate") do
      Rails.logger.info "Starting game update..."
      puts "Starting game update..."

      updated_games = Gateways.game.fetch_all_updated_games

      Game.transaction do
        updated_games.each_slice(1000) do |batch|
          games_to_update = batch.map do |game|
            {
              igdb_id: game.id,
              name: game.name || "N/A",
              release_date: game.first_release_date || nil,
              platforms: game.platforms ? game.platforms.map(&:name) : [],
              cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
              igdb_url: "https://www.igdb.com/games/#{game.slug}",
              created_at: game.created_at ? Time.at(game.created_at).utc : Time.current.utc,
              updated_at: game.updated_at ? Time.at(game.updated_at).utc : Time.current.utc
            }
          end

          Game.upsert_all(games_to_update, unique_by: :igdb_id)
          print "."  # Progress indicator
        rescue => e
          Rails.logger.error "Error batch updating games: #{e.message}"
          puts "Error batch updating games: #{e.message}"
        end
      end

      message = "Updated #{updated_games.count} games successfully."
      Rails.logger.info message
      puts message
    rescue => e
      Rails.logger.error "Error updating games from API: #{e.message}"
      Rails.logger.error e.backtrace&.join("\n")
      puts "Error updating games from API: #{e.message}"
    end
  end
end
