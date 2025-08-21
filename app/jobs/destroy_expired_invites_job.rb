# frozen_string_literal: true

class DestroyExpiredInvitesJob < ApplicationJob
  queue_as :default

  sidekiq_options queue: :default, retry: 3, backtrace: 20

  def perform
    Invite.destroy_expired_invites
  rescue => e
    Sidekiq.logger.error("DestroyExpiredInvitesJob failed: #{e.message}")
    raise # re-raise to allow Sidekiq to retry
  end
end
