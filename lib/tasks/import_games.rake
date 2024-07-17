require "date"
# One time task to initialize the database with games from the IGDB API
namespace :db do
  desc "Import games from IGDB API"
  task import_games: :environment do
    games = Gateways.game.get_all_games(fields: "id, slug, name, cover.url, platforms.name, first_release_date")

    Game.transaction do
      games.each_slice(1000) do |batch|
        games_to_insert = batch.map do |game|
          {
            id: game.id,
            name: game.name || "N/A",
            release_date: game.first_release_date ? Time.at(game.first_release_date).utc.to_datetime : nil,
            platforms: game.platforms ? game.platforms.map(&:name) : [],
            cover_image_url: game.cover&.url,
            igdb_url: "https://www.igdb.com/games/#{game.slug}",
            created_at: Time.now.utc,
            updated_at: Time.now.utc
          }
        end

        begin
          Game.upsert_all(games_to_insert, unique_by: :id)
          print "."  # Progress indicator
        rescue => e
          puts "Error inserting batch: #{e.message}"
        end
      end
    end

    puts "\nImported #{Game.count} games successfully!"
  end
end
