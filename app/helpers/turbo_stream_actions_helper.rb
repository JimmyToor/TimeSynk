# frozen_string_literal: true

module TurboStreamActionsHelper
  def frame_reload(frame_id)
    turbo_stream_action_tag :reload, target: frame_id
  end

  # Creates a turbo stream that adds a toast notification to the container
  #
  # @param type [Symbol] The toast type (:success, :error, :warning, etc.)
  # @param message [String] The message to display
  # @param id [String] Optional unique ID for the toast
  # @param options [Hash] Additional options for the toast
  #
  # @option options [String] :highlight The text in the message to highlight. Only highlights the first occurrence.
  # @option options [String] :list_items An array of items to display as a list below the message.
  # @option options [String] :link A hash containing the link text and URL. Example: { text: "Click here", url: "/path" }. Only links the first occurrence.
  #
  # @return [String] Turbo Stream HTML for appending the toast
  def turbo_stream_toast(type, message, id = nil, **options)
    turbo_stream.append "toast_container", partial: "shared/toast",
      locals: {
        type: type,
        message: message,
        id: id,
        options: options
      }
  end

  def notification
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
