# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "csv"

User.create(
  email: "test@test.com",
  password: "mypassword123",
  password_confirmation: "mypassword123",
  username: "Admin User",
  verified: true,
  timezone: "America/Los_Angeles"
).add_role(:site_admin)

User.create(
  email: "normaluser@test.com",
  password: "mypassword123",
  password_confirmation: "mypassword123",
  username: "Normal User",
  verified: true,
  timezone: "America/Los_Angeles"
)

User.create(
  email: "europeonperson@test.com",
  password: "mypassword123",
  password_confirmation: "mypassword123",
  username: "European Person",
  verified: true,
  timezone: "Europe/London"
)

file_path = "./db/seeds/games.csv"

games = []

CSV.foreach(file_path, headers: true) do |row|
  game = {
    igdb_id: row["igdb_id"],
    name: row["name"],
    release_date: row["release_date"] ? Time.at(row["release_date"].to_i).to_date : nil,
    platforms: row["platforms"],
    cover_image_url: row["cover_image_url"]? "https:#{row["cover_image_url"]}" : nil,
    igdb_url: row["igdb_url"],
    created_at: row["created_at"],
    updated_at: row["updated_at"]
  }
  games << game
end

Game.transaction do
  print "Inserting games..."
  games.each_slice(1000) do |batch|
    games_to_insert = batch.map do |game|
      {
        igdb_id: game[:igdb_id],
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
      Game.upsert_all(games_to_insert, unique_by: :igdb_id)
      print "."  # Progress indicator
    rescue => e
      puts "Error inserting batch: #{e.message}"
    end
  end
  puts "Imported games from CSV successfully!"
end
