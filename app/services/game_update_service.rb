# frozen_string_literal: true

class GameUpdateService
  require "date"

  class UpdateError < StandardError; end

  class BatchError < UpdateError
    attr_reader :start_id, :end_id, :size, :index, :cause

    def initialize(start_id:, end_id:, size:, index:, cause:)
      @start_id = start_id
      @end_id = end_id
      @size = size
      @index = index
      @cause = cause
      super("Batch update failed for games in batch #{index}. Start ID: #{start_id}, End ID: #{end_id}, Size: #{size}. Cause: #{cause.class} - #{cause.message}")
      set_backtrace(cause.backtrace)
    end
  end

  class PartialUpdateError < UpdateError
    attr_reader :failed_batches

    def initialize(failed_batches:)
      @failed_batches = failed_batches
      super("Partial update completed with errors for #{failed_batches.count} batches: #{failed_batches.map(&:index).join(", ")}")
    end
  end

  BATCH_SIZE = 500

  def self.call
    new.call
  end

  def call
    Rails.logger.tagged("GamesAPIUpdate") do
      start_time = Time.current
      log_info "Starting game update..."

      batch_errors = []
      batch_index = 0

      Game.transaction do
        Gateways.game.each_updated_game_batch(limit: BATCH_SIZE) do |batch|
          batch_index += 1
          upsert_batch(batch)
          log_info "Batch #{batch_index} processed, size: #{batch.size}"
        rescue => e
          log_error "Error processing batch #{batch_index}: #{e.message}"
          error = BatchError.new(start_id: batch.first.id, end_id: batch.last.id, index: batch_index, size: batch.size, cause: e)
          batch_errors << error
        end
      end

      elapsed = Time.current - start_time

      if batch_errors.any?
        log_error "Partial update completed in #{elapsed.round(2)}s with #{batch_errors.count} failed batches out of #{batch_index}."
        raise PartialUpdateError.new(failed_batches: batch_errors)
      else
        log_info "Game update completed successfully in #{elapsed.round(2)}s. Updated #{batch_index * BATCH_SIZE} games."
      end
    end
  rescue PartialUpdateError
    raise
  rescue UpdateError => e
    message = "Game update service encountered an unrecoverable error: #{e.message}"
    log_error(message)
    raise UpdateError, message
  end

  private

  def upsert_batch(batch)
    games_to_update = batch.map do |game|
      {
        igdb_id: game.id,
        name: game.name || "N/A",
        release_date: game.first_release_date ? Time.at(game.first_release_date).utc : nil,
        platforms: game.platforms ? game.platforms.map(&:name) : [],
        cover_image_url: game.cover&.url.present? ? "https:#{game.cover.url}" : nil,
        igdb_url: "https://www.igdb.com/games/#{game.slug}",
        created_at: game.created_at ? Time.at(game.created_at).utc : Time.current.utc,
        updated_at: game.updated_at ? Time.at(game.updated_at).utc : Time.current.utc
      }
    end
    Game.upsert_all(games_to_update, unique_by: :igdb_id)
  end

  def log_error(message)
    Rails.logger.error message
    puts message
  end

  def log_info(message)
    Rails.logger.info message
    puts message
  end
end
