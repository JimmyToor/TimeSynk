require "date"

# Repeatable task to update the games in the database from the IGDB API
namespace :db do
  desc "Update games in db, only changing records that need updates"
  task update_games: :environment do
    GameUpdateService.call
  rescue GameUpdateService::PartialUpdateError => e
    puts "Rake task partial failure: #{e.message}"
    exit 2
  rescue GameUpdateService::UpdateError => e
    puts "Rake task failed: #{e.message}"
    exit 1
  rescue => e
    puts "Rake task unexpected error: #{e.class} - #{e.message}"
    puts e.backtrace.join("\n")
    exit 99
  end
end
