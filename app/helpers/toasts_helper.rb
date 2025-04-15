# frozen_string_literal: true

module ToastsHelper
  def format_toast_message(message, options = {})
    # Reuse the notification helper for consistent formatting
    format_notification_message(message, options)
  end

  def toast_icon_classes(type)
    case type.to_sym
    when :success
      "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-200"
    when :alert, :error
      "text-red-500 bg-red-100 dark:bg-red-800 dark:text-red-200"
    when :warning, :danger
      "text-yellow-500 bg-yellow-100 dark:bg-yellow-800 dark:text-yellow-200"
    when :notice, :info
      "text-blue-500 bg-blue-100 dark:bg-blue-800 dark:text-blue-200"
    else
      "text-gray-500 bg-gray-100 dark:bg-gray-800 dark:text-gray-200"
    end
  end

  def toast_icon(type)
    type = type.to_sym if type.is_a?(String)
    case type
    when :success
      '<svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 8.207-4 4a1 1 0 0 1-1.414 0l-2-2a1 1 0 0 1 1.414-1.414L9 10.586l3.293-3.293a1 1 0 0 1 1.414 1.414Z"/>
      </svg>'.html_safe
    when :alert, :error
      '<svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 14.793L10 11.586l-3.707 3.707a1 1 0 0 1-1.414-1.414L8.586 10 4.879 6.293a1 1 0 0 1 1.414-1.414L10 8.586l3.707-3.707a1 1 0 0 1 1.414 1.414L11.414 10l3.707 3.707a1 1 0 0 1-1.414 1.414Z"/>
      </svg>'.html_safe
    when :warning, :danger
      '<svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM10 15a1 1 0 1 1 0-2 1 1 0 0 1 0 2Zm1-4a1 1 0 0 1-2 0V6a1 1 0 0 1 2 0v5Z"/>
      </svg>'.html_safe
    when :notice, :info
      '<svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z"/>
      </svg>'.html_safe
    else
      '<svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z"/>
      </svg>'.html_safe
    end
  end
end
