require "csv"

# One time task to initialize the database with games from the CSV
namespace :db do
  desc "Import games from CSV"
  task import_games: :environment do
    file_path = "./db/seeds/games.csv"

    unless File.exist?(file_path)
      puts "Error: Games CSV file not found at #{file_path}"
      next
    end

    unless File.extname(file_path) == ".csv"
      puts "Error: The file is not a CSV file."
      next
    end

    unless File.size(file_path) > 0
      puts "Error: The CSV file is empty."
      next
    end
    games = []

    CSV.foreach(file_path, headers: true) do |row|
      game = {
        igdb_id: row["igdb_id"],
        name: row["name"],
        release_date: row["release_date"] ? Time.at(row["release_date"]).utc.to_datetime : nil,
        platforms: row["platforms"].split(", ").map { |platform| platform.gsub(/['"]/, "") },
        cover_image_url: row["cover_image_url"] || nil,
        igdb_url: row["igdb_url"],
        is_popular: row["is_popular"] || false,
        created_at: row["created_at"],
        updated_at: row["updated_at"]
      }
      games << game
    end

    Game.transaction do
      print "Inserting games..."
      games.each_slice(5000) do |batch|
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
          Game.upsert_all(games_to_insert, unique_by: :igdb_id, returning: false)
          print "."  # Progress indicator
        rescue => e
          puts "Error inserting batch: #{e.message}"
        end
      end
      puts "Imported games from CSV successfully!"
    end
  end
end
