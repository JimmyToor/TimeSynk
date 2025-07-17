# frozen_string_literal: true

module DurationSaturator
  extend ActiveSupport::Concern

  # Populates params :duration using the parts in :duration_days, :duration_hours, and :duration_minutes.
  # Overflowing parts are added to the next largest unit i.e. 61 minutes becomes 1 hour and 1 minute.
  # Deletes the parts from the params hash after conversion.
  # @param key_path [Array<Symbol>] the key path to the duration hash
  def populate_duration_param(key_path)
    param_hash = params.dig(*key_path)
    return unless param_hash.present? && param_hash[:duration].blank?

    param_hash[:duration_days] = param_hash[:duration_days].to_i
    param_hash[:duration_hours] = param_hash[:duration_hours].to_i
    param_hash[:duration_minutes] = param_hash[:duration_minutes].to_i

    if param_hash[:duration_minutes].present? && param_hash[:duration_minutes] > 59
      param_hash[:duration_hours] = param_hash[:duration_hours] + (param_hash[:duration_minutes] / 60)
      param_hash[:duration_minutes] = param_hash[:duration_minutes] % 60
    end

    if param_hash[:duration_hours].present? && param_hash[:duration_hours] > 23
      param_hash[:duration_days] = param_hash[:duration_days] + (param_hash[:duration_hours] / 24)
      param_hash[:duration_hours] = param_hash[:duration_hours] % 24
    end

    param_hash[:duration] = param_hash[:duration_days].days +
      param_hash[:duration_hours].hours +
      param_hash[:duration_minutes].minutes

    param_hash.delete(:duration_minutes)
    param_hash.delete(:duration_days)
    param_hash.delete(:duration_hours)
  end
end
