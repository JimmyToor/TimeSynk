module ApplicationHelper
  include Pagy::Frontend

  def match_request_frame_ids(frame_ids, alternate_frame_id)
    if turbo_frame_request? && frame_ids.include?(turbo_frame_request_id)
      turbo_frame_request_id
    else
      alternate_frame_id
    end
  end

  # Renders a block in a modal if the request is a turbo frame request with the ID "modal_frame"
  #
  # @param modal_title [String] The title of the modal
  # @yieldparam blk The block of content to be rendered inside the modal
  # @return [String] The rendered modal or the captured block content
  #
  # @example
  #   <%= modal_wrapper("My Modal Title") do %>
  #     <p>This is the content of the modal.</p>
  #   <% end %>
  def modal_wrapper(modal_title, &blk)
    if turbo_frame_request_id == "modal_frame"
      render partial: "shared/modal", locals: {modal_title: modal_title, modal_body: capture(&blk)}
    else
      capture(&blk)
    end
  end

  def modal_wrapper?
    turbo_frame_request_id == "modal_frame"
  end

  # Generates a data attribute for opening or closing a dialog based on the value
  # @param value [Boolean] The value to check
  def open_unless_value(value)
    value ? "data-dialog-open-value=false" : "data-dialog-open-value=true"
  end

  # Formats a time interval into a human-readable string
  # @param interval [ActiveSupport::Duration] The time interval to format
  def format_interval(interval)
    parts = []
    parts << "#{interval.parts[:days]}d" if interval.parts[:days]
    parts << "#{interval.parts[:hours]}h" if interval.parts[:hours]
    parts << "#{interval.parts[:minutes]}m" if interval.parts[:minutes]
    parts.join(" ")
  end

  # Formats a time interval into a screen reader friendly string
  # @param interval [ActiveSupport::Duration] The time interval to format
  def format_interval_sr(interval)
    parts = []
    parts << pluralize(interval.parts[:days], t("time.day")).to_s if interval.parts[:days]
    parts << pluralize(interval.parts[:hours], t("time.hour")).to_s if interval.parts[:hours]
    parts << pluralize(interval.parts[:minutes], t("time.minute")).to_s if interval.parts[:minutes]
    parts.join(" ")
  end

  def input_field_classes
    "bg-tertiary-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg
                              focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700
                              dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500
                              dark:focus:border-blue-500"
  end

  def modal_link_classes
    "text-secondary-500 hover:text-secondary-400 dark:text-secondary-200 dark:hover:text-secondary-100"
  end
end
