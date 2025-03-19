require "date"

# Repeatable task to update the games marked as popular in the database from the IGDB API
namespace :db do
  desc "Update popularity of games in db"
  task update_popularity: :environment do
    Rails.logger.tagged("GamesPopularityAPIUpdate") do
      Rails.logger.info "Starting popularity update..."
      puts "Starting popularity update..."

      new_popular_ids = Gateways.game.fetch_popular_game_ids(limit: 100).each.map(&:game_id)
      currently_popular_ids = Game.where(is_popular: true).pluck(:igdb_id)

      no_longer_popular = currently_popular_ids - new_popular_ids
      newly_popular = new_popular_ids - currently_popular_ids

      Game.transaction do
        if no_longer_popular.present?
          no_longer_popular.each_slice(1000) do |batch|
            Game.where(igdb_id: batch).update_all(is_popular: false)
            print "."  # Progress indicator
          rescue => e
            puts "Error batch updating no longer popular: #{e.message}"
          end
        end

        if newly_popular.present?
          newly_popular.each_slice(1000) do |batch|
            Game.where(igdb_id: batch).update_all(is_popular: true)
            print "."  # Progress indicator
          rescue => e
            puts "Error batch updating newly popular: #{e.message}"
          end
        end
      end

      message = "\nUpdated popularity: #{newly_popular&.size || 0} new, #{no_longer_popular.size || 0} removed"
      Rails.logger.info message
      puts message
    rescue => e
      Rails.logger.error "Error updating popularity: #{e.message}"
      Rails.logger.error e.backtrace&.join("\n")
      puts "Error updating popularity: #{e.message}"
    end
  end
end
