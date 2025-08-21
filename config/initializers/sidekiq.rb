require "sidekiq"
require "sidekiq-cron"

if defined?(Sidekiq) && Rails.const_defined?(:Server)
  Sidekiq.configure_server do |config|
    config.redis = {url: ENV.fetch("REDIS_URL")}

    schedule_file = "config/sidekiq.yml"
    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(schedule["schedule"] || schedule[:schedule])
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = {url: ENV.fetch("REDIS_URL")}
  end
end
