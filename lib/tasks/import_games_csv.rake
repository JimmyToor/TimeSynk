require 'csv'

namespace :import do
  desc 'Import games from CSV'
  task games_csv: :environment do
    file_path = "./games.csv"

    games = []

    CSV.foreach(file_path, headers: true) do |row|
      game = {
        id: row['igdb_id'],
        name: row['name'],
        release_date: row['release_date'],
        platforms: row['platforms'].split(', '),
        cover_image_url: row['cover_image_url'],
        igdb_url: row['igdb_url'],
        created_at: row['created_at'],
        updated_at: row['updated_at']
      }
      games << game
    end

    Game.transaction do
      games.each_slice(1000) do |batch|
        games_to_insert = batch.map do |game|
          {
            id: game[:id],
            name: game[:name] || "N/A",
            release_date: game[:release_date] || nil,
            platforms: game[:platforms] || [],
            cover_image_url: game[:cover_image_url] || nil,
            igdb_url: game[:igdb_url],
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        begin
          Game.upsert_all(games_to_insert, unique_by: :id)
          print '.'  # Progress indicator
        rescue => e
          puts "Error inserting batch: #{e.message}"
        end
      end
    end

    puts "Imported games from CSV successfully!"
    puts "Games: #{games.inspect}"
  end
end