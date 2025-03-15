# frozen_string_literal: true

# Create admin user using credentials
if Rails.application.credentials.admin.present?
  admin_config = Rails.application.credentials.admin

  User.find_or_create_by(
    email: admin_config[:email],
    username: admin_config[:username],
    verified: true,
    timezone: admin_config[:timezone] || "UTC"
  ) do |user|
    user.password = admin_config[:password]
    user.password_confirmation = admin_config[:password]
    user.add_role(:site_admin) unless user.has_role?(:site_admin)
  end
  puts "Admin user created or updated from credentials"
end
