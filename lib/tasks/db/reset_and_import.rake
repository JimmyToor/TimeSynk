namespace :db do
  desc "Reset the database and import games from CSV"
  task reset_and_import: :environment do
    Rake::Task["db:reset"].invoke
    Rake::Task["db:import_games"].invoke
    Rake::Task["db:update_popularity"].invoke
  end
end
