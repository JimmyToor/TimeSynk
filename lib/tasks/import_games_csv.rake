require 'csv'

namespace :import do
  desc 'Import games from CSV'
  task games_csv: :environment do
    file_path = "./games.csv"

    games = []

    CSV.foreach(file_path, headers: true) do |row|
      game = {
        id: row['ID'],
        name: row['Name'],
        release_date: row['Release Date'],
        platforms: row['Platforms'].split(', '),
        cover_image_url: row['Cover Image URL'],
        igdb_url: row['IGDB URL'],
        created_at: row['Created At'],
        updated_at: row['Updated At']
      }
      games << game
      if game[:id] == "1"
        break
      end
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