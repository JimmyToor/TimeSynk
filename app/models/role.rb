class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
    polymorphic: true,
    optional: true

  validates :resource_type,
    inclusion: {in: Rolify.resource_types},
    allow_nil: true

  scopify

  def self.create_roles_for_group(group)
    Role.create(name: "owner", resource: group)
    Role.create(name: "admin", resource: group)
    Role.create(name: "manage_invites", resource: group)
    Role.create(name: "kick_users", resource: group)
    Role.create(name: "create_game_proposals", resource: group)
    Role.create(name: "manage_all_game_proposals", resource: group)
    nil
  end

  def self.create_roles_for_game_proposal(proposal)
    Role.create(name: "owner", resource: proposal)
    Role.create(name: "admin", resource: proposal)
    Role.create(name: "create_game_sessions", resource: proposal)
    Role.create(name: "manage_all_game_sessions", resource: proposal)
    nil
  end

  def self.create_roles_for_game_session(game_session)
    Role.create(name: "owner", resource: game_session)
    nil
  end
end
