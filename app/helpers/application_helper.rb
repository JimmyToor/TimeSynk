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

  def modal_link_text_classes
    "text-secondary-500 hover:text-secondary-400 dark:text-secondary-200 dark:hover:text-secondary-100"
  end

  def modal_link_bg_classes
    "bg-secondary-500 hover:bg-secondary-400 focus:ring-secondary-300 dark:bg-secondary-400 dark:hover:bg-secondary-300 dark:focus:ring-secondary-200"
  end

  def visit_link_bg_classes
    "bg-primary-500 hover:bg-primary-400 dark:bg-primary-700 dark:hover:bg-primary-600"
  end

  def visit_link_text_classes
    "text-black hover:text-gray-100 dark:text-gray-200 dark:hover:text-gray-100"
  end

  def policy_class_for_resource(resource)
    policy_class_name = "#{resource.class}Policy"
    policy_class = policy_class_name.safe_constantize
    raise NameError, "Uninitialized constant #{policy_class_name}. Could not find the policy for #{resource.class.name}." unless policy_class

    policy_class
  end
end
