# frozen_string_literal: true

module RolesHelper
  def format_group_role(role)
    I18n.t("group.role.#{role.name}", default: role.name.humanize)
  end

  def format_game_proposal_role(role)
    I18n.t("game_proposal.role.#{role.name}", default: role.name.humanize)
  end

  def format_game_session_role(role)
    I18n.t("game_session.role.#{role.name}", default: role.name.humanize)
  end
end
