require "csv"

# One time task to initialize the database with games from the CSV
namespace :db do
  desc "Export games to CSV"
  task export_games: :environment do
    Rails.logger.tagged("GamesExport") do
      file_path = "./db/seeds/games.csv"
      headers = %w[igdb_id name release_date platforms cover_image_url igdb_url is_popular created_at updated_at]

      begin
        CSV.open(file_path, "w", headers: headers, write_headers: true) do |csv|
          total_count = Game.count
          processed_count = 0

          Game.find_in_batches(batch_size: 1000) do |batch|
            batch.each do |game|
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
              processed_count += 1
            rescue => e
              Rails.logger.error "Error exporting game ID: #{game.id}, igdb_id: #{game.igdb_id}: #{e.message}"
              puts "Error on game ID: #{game.id}, igdb_id: #{game.igdb_id}: #{e.message}"
            end

            puts "Processed #{processed_count}/#{total_count} games..."
          rescue => batch_error
            Rails.logger.error "Error processing batch: #{batch_error.message}"
            puts "Error processing batch: #{batch_error.message}"
          end
        end

        puts "\nExported games to CSV successfully at #{file_path}!"
      rescue => e
        Rails.logger.error "Error setting up CSV export: #{e.message}"
        puts "Error setting up CSV export: #{e.message}"
      end
    end
  end
end
