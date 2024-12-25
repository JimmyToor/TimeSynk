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

User.create(
  password: "aaaaaaaa",
  password_confirmation: "aaaaaaaa",
  username: "Email-less User",
  verified: false,
  timezone: "America/Los_Angeles"
)