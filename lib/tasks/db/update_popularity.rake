require "date"
# One time task to initialize the database with games from the IGDB API
namespace :db do
  desc "Update popularity of games in db"
  task update_popularity: :environment do
    popular_game_ids = Gateways.game.fetch_popular_game_ids(limit: 100).each.map(&:game_id)

    Game.transaction do
      Game.update_all(is_popular: false)

      popular_game_ids.each_slice(1000) do |batch|
        popular_games = Game.where(igdb_id: batch)
        begin
          popular_games.update_all(is_popular: true)
          print "."  # Progress indicator
        rescue => e
          puts "Error batch updating popularity: #{e.message}"
        end
      end
    end

    puts "\nUpdated #{popular_game_ids.count} games successfully!"
  end
end
