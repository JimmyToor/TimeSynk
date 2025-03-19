# frozen_string_literal: true

module AppConfig
  def self.get(key, default = nil)
    # In development, use ENV variables.
    # In production, check credentials first, then ENV variables.
    if Rails.env.production?
      # Try credentials first, fall back to ENV if not found
      credential_value = Rails.application.credentials.dig(*key.to_s.downcase.split(".").map(&:to_sym))
      return credential_value unless credential_value.nil?
    end

    # Convert key from its credentials format to ENV format
    # e.g., "IGDB.CLIENT" becomes "IGDB_CLIENT"
    env_key = key.to_s.include?(".") ? key.to_s.tr(".", "_") : key.to_s
    ENV.fetch(env_key, default)
  end
end
