# frozen_string_literal: true

User.find_or_create_by(
  email: "test@test.com",
  username: "Admin User",
  verified: true,
  timezone: "America/Los_Angeles"
) do |user|
  user.password = "mypassword123"
  user.password_confirmation = "mypassword123"
  user.add_role(:site_admin)
end

User.find_or_create_by(
  email: "normaluser@test.com",
  username: "Normal User",
  verified: true,
  timezone: "America/Los_Angeles"
) do |user|
  user.password = "mypassword123"
  user.password_confirmation = "mypassword123"
end

User.find_or_create_by(
  email: "europeonperson@test.com",
  username: "European Person",
  verified: true,
  timezone: "Europe/London"
) do |user|
  user.password = "mypassword123"
  user.password_confirmation = "mypassword123"
end

User.find_or_create_by(
  username: "Email-less User",
  verified: false,
  timezone: "America/Los_Angeles"
) do |user|
  user.password = "aaaaaaaa"
  user.password_confirmation = "aaaaaaaa"
end
