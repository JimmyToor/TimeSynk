class User < ApplicationRecord
  rolify strict: true
  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end
  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  belongs_to :account
  has_many :sessions, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships # user is a member of
  has_many :invites, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  has_many :game_proposals, dependent: :destroy, through: :groups
  has_many :game_sessions, dependent: :destroy, through: :game_proposals
  has_many :game_session_attendances, dependent: :destroy
  has_many :proposal_votes, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_one :user_availability, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy
  has_many :user_availability_schedules, through: :user_availability, source: :schedules, dependent: :destroy
  has_many :group_availability_schedules, through: :group_availabilities, source: :schedules, dependent: :destroy
  has_many :proposal_availability_schedules, through: :proposal_availabilities, source: :schedules, dependent: :destroy
  has_one_attached :avatar

  normalizes :username, with: ->(username) { username.squish }

  validates :avatar,
    processable_image: true,
    content_type: {with: [:png, :jpg, :gif], spoofing_protection: true},
    size: {less_than: 1.megabyte}, if: -> { avatar.attached? }

  validates :email, uniqueness: {case_sensitive: false, allow_blank: true, if: :verified?},
    format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validate :email_not_verified_by_others, if: -> { email.present? }
  validates :username, presence: true, uniqueness: true, length: {minimum: 3, maximum: 20}
  validates :password, allow_nil: false, length: {minimum: 8}, if: :password_digest_changed?

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account = Account.new
  end

  before_validation if: -> { verified_changed? && verified? } do
    clear_email_from_other_users
  end

  after_create_commit :create_initial_user_availability

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def email_not_verified_by_others
    existing_verified_user = User.where(email: email, verified: true)
      .where.not(id: id)
      .exists?

    if existing_verified_user
      errors.add(:email, "is already taken")
    end
  end

  def roles_for_resource(resource)
    roles.where(resource: resource)
  end

  def supersedes_user_in_resource?(role_user, resource)
    role_user_most_permissive_role = role_user.most_permissive_cascading_role_for_resource(resource)
    our_most_permissive_role = most_permissive_cascading_role_for_resource(resource)
    RoleHierarchy.supersedes?(our_most_permissive_role, role_user_most_permissive_role)
  end

  # Returns the highest role a user has for a particular resource.
  def most_permissive_role_for_resource(resource)
    roles.where(resource: resource).min_by { |role| RoleHierarchy.role_weight(role) }
  end

  def most_permissive_role_weight_for_resource(resource)
    roles.where(resource: resource).map { |role| RoleHierarchy.role_weight(role) }.min || RoleHierarchy::NON_PERMISSIVE_WEIGHT
  end

  # Returns the highest role a user has for a particular resource, including roles from parent resources.
  def most_permissive_cascading_role_for_resource(resource)
    current_highest_role = most_permissive_role_for_resource(resource)

    return current_highest_role unless resource.class.respond_to?(:role_providing_associations)

    resource.class.role_providing_associations.each do |association_name|
      parent_resource = resource.send(association_name)
      next if parent_resource.nil?

      parent_highest_role = most_permissive_cascading_role_for_resource(parent_resource)

      if RoleHierarchy.supersedes?(parent_highest_role, current_highest_role)
        current_highest_role = parent_highest_role
      end
    end
    current_highest_role
  end

  # @return [Hash<Role>] The roles that we can add/remove for the affected user relative to the resource
  def available_roles_for_resource(affected_user, resource, cascading: false)
    roles = {}
    most_permissive_role = most_permissive_cascading_role_for_resource(resource)
    return roles if most_permissive_role.nil? || most_permissive_role == RoleHierarchy::NON_PERMISSIVE_WEIGHT

    if supersedes_user_in_resource?(affected_user, resource)
      roles[resource.model_name.param_key.to_sym] = resource.roles.reject { |role| RoleHierarchy.special?(role) }
      if cascading && resource.class.respond_to?(:role_providing_associations)
        resource.class.role_providing_associations.each do |association_name|
          parent_resource = resource.send(association_name)
          next if parent_resource.nil?

          roles.merge!(available_roles_for_resource(affected_user, parent_resource, cascading: true))
        end
      end
    end
    roles
  end

  def update_roles(add_roles: [], remove_roles: [])
    RoleUpdateService.call(self, add_roles, remove_roles)
  end

  def get_membership_for_group(group)
    group_memberships.find_by(group: group, user: self)
  end

  def get_vote_for_proposal(proposal)
    proposal_votes.find_by(game_proposal: proposal)
  end

  def get_attendance_for_game_session(game_session)
    game_session_attendances.find_by(game_session: game_session)
  end

  def nearest_proposal_availability(game_proposal)
    game_proposal.get_user_proposal_availability(self)&.availability || nearest_group_availability(game_proposal.group)
  end

  def make_permission_set_for_resource(resource)
    raise ArgumentError, "No resource provided for user (#{user.username}) permission set." if resource.nil?
    resource.make_permission_set([self])
  end

  def nearest_group_availability(group)
    group.get_user_group_availability(self)&.availability || user_availability.availability
  end

  def create_initial_user_availability
    return unless user_availability.nil?

    availability = Availability.create!(user: self,
      name: "Default Availability",
      description: "Default Availability for #{username}")
    self.user_availability = UserAvailability.create!(user: self, availability: availability)
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:user_availability, message: "could not be created: #{e.message}")
  end

  def upcoming_game_sessions(date_limit: 1.month.from_now)
    if date_limit.nil?
      game_sessions.where("date >= ?", Time.current)
    else
      game_sessions.where("date >= ? AND date <= ?", Time.current, date_limit)
    end
  end

  def pending_game_proposals
    game_proposals.reject { |proposal| proposal.user_voted?(self) }.sort_by(&:created_at)
  end

  def pending_game_proposal_count
    pending_game_proposals.count
  end

  def groups_user_can_create_proposals_for
    groups.select { |group| GroupPolicy.new(self, group).create_game_proposal? }
  end

  def game_proposals_user_can_create_sessions_for
    game_proposals.select do |proposal|
      GameProposalPolicy.new(self, proposal).create_game_session?
    end
  end

  def broadcast_role_change_for_resource(resource)
    broadcast_action_to(
      "user_roles_#{id}",
      action: "frame_reload",
      target: "user_roles_#{id}_#{resource.model_name.param_key}_#{resource.id}",
      render: false
    )
  end

  def has_any_role_for_resource?(roles_to_check, resource)
    roles_to_check.any? { |role| has_cached_role?(role, resource) }
  end

  # Clears the email of other users who have the same email address when this user is verified.
  def clear_email_from_other_users
    return unless verified? && email.present?

    # Find users with the same email who are not this user
    User.where(email: email)
      .where.not(id: id)
      .update_all(email: nil)
  end
end
