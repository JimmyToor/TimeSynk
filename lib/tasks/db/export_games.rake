require "csv"

# One time task to initialize the database with games from the CSV
namespace :db do
  desc "Export games to CSV"
  task export_games: :environment do
    Rails.logger.tagged("GamesExport") do
      file_path = "./db/seeds/games.csv"

      games = Game.all

      headers = %w[igdb_id name release_date platforms cover_image_url igdb_url is_popular created_at updated_at]

      CSV.open(file_path, "w", headers: headers, write_headers: true) do |csv|
        games.find_each.with_index do |game, index|
          csv << [
            game.igdb_id,
            game.name,
            game.release_date ? game.release_date.to_time.to_i : nil,
            game.platforms&.join(", "),
            game.cover_image_url,
            game.igdb_url,
            game.is_popular,
            game.created_at,
            game.updated_at
          ]

          if (index + 1) % 1000 == 0
            puts "." # Print progress
          end
        end
      end

      puts "\nExported games to CSV successfully at #{file_path}!"
    rescue => e
      Rails.logger.error "Error exporting games to CSV: #{e.message}"
      puts "Error exporting games to CSV: #{e.message}"
    end
  end
end
