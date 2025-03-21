require "csv"

# One time task to initialize the database with games from the CSV
namespace :db do
  desc "Import games from CSV"
  task import_games: :environment do
    Rails.logger.tagged("GamesImport") do
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

      CSV.foreach(file_path, headers: true).each_slice(5000) do |batch|
        Game.transaction do
          games_to_insert = batch.map do |row|
            {
              igdb_id: row["igdb_id"],
              name: row["name"] || "N/A",
              release_date: row["release_date"] ? Time.at(row["release_date"].to_i).utc.to_datetime : nil,
              platforms: row["platforms"] ? row["platforms"].split(", ").map { |p| p.gsub(/['"]/, "") } : [],
              cover_image_url: row["cover_image_url"],
              igdb_url: row["igdb_url"],
              is_popular: row["is_popular"] == "true",
              created_at: Time.current,
              updated_at: Time.current
            }
          rescue => e
            Rails.logger.error "Error processing row: #{row.inspect} - #{e.message}"
            nil
          end.compact

          if games_to_insert.any?
            begin
              Game.upsert_all(games_to_insert, unique_by: :igdb_id, returning: false)
              print "."  # Progress indicator
            rescue => e
              puts "Error inserting batch: #{e.message}"
            end
          end
        end
      rescue => e
        puts "Error reading CSV file: #{e.message}"
        next
      end
    end
  end
end
