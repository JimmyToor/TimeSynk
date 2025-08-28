require "sidekiq"
require "sidekiq-cron"

if defined?(Sidekiq) && Rails.const_defined?(:Server)
  schedule_file = "config/sidekiq.yml"
  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(schedule["schedule"] || schedule[:schedule])
  end
end
