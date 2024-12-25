require 'csv'

namespace :db do
  desc "Import games from CSV"
  task import_games: :environment do
    file_path = "./db/seeds/games.csv"

    games = []

    CSV.foreach(file_path, headers: true) do |row|
      game = {
        igdb_id: row["igdb_id"],
        name: row["name"],
        release_date: row["release_date"] ? Time.at(row["release_date"].to_i).to_date : nil,
        platforms: row["platforms"].split(', ').map { |platform| platform.gsub(/['"]/, "") },
        cover_image_url: row["cover_image_url"]? row["cover_image_url"] : nil,
        igdb_url: row["igdb_url"],
        is_popular: row["is_popular"] || false,
        created_at: row["created_at"],
        updated_at: row["updated_at"]
      }
      games << game
    end

    Game.transaction do
      print "Inserting games..."
      games.each_slice(1000) do |batch|
        games_to_insert = batch.map do |game|
          {
            igdb_id: game[:igdb_id],
            name: game[:name] || "N/A",
            release_date: game[:release_date] || nil,
            platforms: game[:platforms] || [],
            cover_image_url: game[:cover_image_url] || nil,
            igdb_url: game[:igdb_url],
            is_popular: game[:is_popular] || false,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        begin
          Game.upsert_all(games_to_insert, unique_by: :igdb_id)
          print "."  # Progress indicator
        rescue => e
          puts "Error inserting batch: #{e.message}"
        end
      end
      puts "Imported games from CSV successfully!"
    end
  end
end
