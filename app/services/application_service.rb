# frozen_string_literal: true

# Base class for all service objects in the application.
# Provides a convenient class method `.call` that initializes an instance
# of the service and calls its `#call` instance method.
class ApplicationService
  # Class method shortcut to instantiate and call the service.
  # Passes all arguments directly to the service's `initialize` method.
  #
  # @param args [*Object] Arguments to be passed to the service's `#initialize` method.
  # @return [Object] The result returned by the service's `#call` instance method.
  def self.call(*args)
    new(*args).call
  end
end
