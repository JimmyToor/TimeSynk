# config/initializers/role_hierarchy.rb
module RoleHierarchy
  ROLE_WEIGHTS = { # in descending order of privilege
    # Global admin (always top)
    site_admin: 0,

    # Group-level roles
    "group.owner": 10,
    "group.admin": 20,

    # Game Proposal roles
    "game_proposal.owner": 100,
    "game_proposal.admin": 110,

    # Game Session roles
    "game_session.owner": 200
  }.freeze

  # Determines if a given role supersedes another role based on their weights.
  #
  # @param role [Role] check if this role supersedes comparison role
  # @param comparison_role [Role] the role to compare against
  # @return [Boolean] true if the role supersedes the comparison_role, false otherwise
  def self.supersedes?(role, comparison_role)
    return false if role == comparison_role || role.nil?
    return true if comparison_role.nil?

    role_weight = role_weight(role)
    comparison_role_weight = role_weight(comparison_role)

    role_weight < comparison_role_weight || false
  end

  # Get the weight of a role
  #
  # @param role [Role] the role to get the weight of
  # @return [Integer] the weight of the role. 1000 if no weight is found
  def self.role_weight(role)
    ROLE_WEIGHTS[role_to_key(role)] || 1000
  end

  def self.role_to_key(role)
    # Convert a Rolify role object to the key format
    # Expects role to have name and resource attributes
    resource_name = role.resource_type.underscore
    :"#{resource_name}.#{role.name}"
  end
end
