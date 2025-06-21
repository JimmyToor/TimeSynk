source "https://rubygems.org"

ruby "3.3.5"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3", ">= 7.1.3.3"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4.2"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails", "~> 1.3.1"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", ">= 2.0.11"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.3.4"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails", "~> 1.4.1"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.12"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.3.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "~> 1.18", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.13"

gem "authentication-zero", "~> 3.0"

gem "active_storage_validations", "~> 1.3"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Use OmniAuth to support multi-provider authentication [https://github.com/omniauth/omniauth]
gem "omniauth", "~> 2.1.2"

# Provides a mitigation against CVE-2015-9284 [https://github.com/cookpad/omniauth-rails_csrf_protection]
gem "omniauth-rails_csrf_protection"

# Use rotp for generating and validating one time passwords [https://github.com/mdp/rotp]
gem "rotp", "~> 6.3.0"

gem "inline_svg", "~> 1.9"

gem "recurring_select", github: "JimmyToor/recurring_select"

gem "rolify", "~> 6.0"

gem "pundit", "~> 2.3"

gem "validates_timeliness", "~> 7.0.0.beta1"

gem "igdb_client", github: "darkstego/igdb_client"

gem "activesupport", "~> 7.1"

gem "csv", "~> 3.3"

gem "pagy", "~> 9.3"

gem "oj", "~> 3.16"

gem "pg_search", "~> 2.3"

gem "rounding", "~> 1.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", "~> 1.9", platforms: %i[mri windows]
  gem "standard", "~> 1.40", require: false
  gem "foreman", "~> 0.88", require: false
  gem "erb_lint", require: false
  gem "rubocop-erb", "~> 0.6.0"
  gem "dotenv-rails", "~> 3.1"
end

group :development do
  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console", "~> 4.2"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.24"
end
