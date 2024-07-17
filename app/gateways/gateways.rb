# frozen_string_literal: true

module Gateways
  def self.game
    @game ||= GameGateway.new
  end
end
