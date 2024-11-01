# frozen_string_literal: true

module RolesHelper
  def format_role_name(role_name)
    role_name.split("_").map(&:capitalize).join(" ")
  end
end
