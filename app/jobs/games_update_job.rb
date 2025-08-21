# frozen_string_literal: true

class GamesUpdateJob < ApplicationJob
  queue_as :default

  sidekiq_options queue: :default, retry: 3, backtrace: 20

  def perform
    GameUpdateService.call
  rescue GameUpdateService::PartialUpdateError
    Sidekiq.logger.error("GameUpdateJob partial update error: #{e.message}")
    raise # re-raise to allow Sidekiq to retry
  rescue GameUpdateService::Error => e
    Sidekiq.logger.error("GameUpdateJob fatal error: #{e.message}")
    raise Sidekiq::JobRetry::Skip
  rescue => e
    Sidekiq.logger.error("GameUpdateJob unexpected error: #{e.message}")
    raise # re-raise to allow Sidekiq to retry
  end
end
