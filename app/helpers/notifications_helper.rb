# frozen_string_literal: true

module NotificationsHelper
  # Displays a notification message with a dismiss button. Valid options keys are:
  #
  #  - :highlight [String] The text in the message to highlight. Only highlights the first occurrence.
  #  - :list_items [Array] An array of items to display as a list below the message.
  #  - :link [Hash] A hash containing the link text and URL. Example: { text: "Click here", url: "/path" }. Only links the first occurrence.
  #
  # @param [Hash] options Hash for customizing the notification. Valid keys are: :highlight, :list_items, :link
  def format_notification_message(message, options = {})
    return message unless options.present?
    options = options.with_indifferent_access if options.respond_to?(:with_indifferent_access)

    if options[:highlight]
      parts = message.split(options[:highlight])
      message = safe_join([
        parts.first,
        content_tag(:strong, options[:highlight], class: "font-bold text-primary-600"),
        parts.last
      ])
    end

    if options[:link]
      parts = message.split(options[:link][:text])
      message = safe_join([
        parts.first,
        link_to(options[:link][:text], options[:link][:url], class: "text-gray-900 dark:text-white underline
           decoration-2 hover:decoration-4 decoration-secondary-500 dark:decoration-secondary-200"),
        parts.last
      ])
    end

    if options[:list_items].present?
      message = safe_join([
        message,
        content_tag(:div) do
          content_tag(:ul, class: "mt-1.5 list-disc list-inside") do
            options[:list_items].map do |item|
              concat content_tag(:li, item)
            end
          end
        end
      ])
    end

    message
  end

  def notification_classes(type)
    case type.to_sym
    when :notice
      "text-blue-800 border-t-4 border-blue-300 bg-blue-50 dark:text-blue-400 dark:bg-gray-800 dark:border-blue-800"
    when :alert, :error
      "text-red-800 border-t-4 border-red-300 bg-red-50 dark:text-red-400 dark:bg-gray-800 dark:border-red-800"
    when :success
      "text-green-800 border-t-4 border-green-300 bg-green-50 dark:text-green-400 dark:bg-gray-800 dark:border-green-800"
    when :danger, :warning
      "text-yellow-800 border-t-4 border-yellow-300 bg-yellow-50 dark:text-yellow-300 dark:bg-gray-800 dark:border-yellow-800"
    when :info
      "border-gray-300 bg-gray-50 dark:bg-gray-800 dark:border-gray-600"
    else
      ""
    end
  end

  def dismiss_button_classes(type)
    case type.to_sym
    when :notice
      "text-blue-500 hover:bg-blue-100 focus:ring-blue-800 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
    when :alert, :error
      "text-red-500 hover:bg-red-100 focus:ring-red-800 dark:hover:bg-red-700 dark:focus:ring-red-800"
    when :success
      "text-green-500 hover:bg-green-100 focus:ring-green-800 dark:hover:bg-green-700 dark:focus:ring-green-800"
    when :danger, :warning
      "text-yellow-500 hover:bg-yellow-100 focus:ring-yellow-800 dark:hover:bg-yellow-700 dark:focus:ring-yellow-800"
    when :info
      "text-gray-500 hover:bg-gray-100 focus:ring-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-800"
    else
      ""
    end
  end
end
