class User < ApplicationRecord
  rolify
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

  validates :avatar, processable_image: true, content_type: {with: [:png, :jpg, :gif], spoofing_protection: true}, size: {less_than: 1.megabyte}, if: -> { avatar.attached? }

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

  def roles_for_game_proposal(proposal)
    roles.where(resource: proposal)
  end

  def roles_for_game_session(game_session)
    roles.where(resource: game_session)
  end

  def supersedes_user_in_game_proposal?(role_user, game_proposal)
    highest_role = highest_role_for_game_proposal(game_proposal)
    highest_role_user_role = role_user.highest_role_for_game_proposal(game_proposal)

    RoleHierarchy.supersedes?(highest_role, highest_role_user_role)
  end

  # Returns the highest role a user has for a particular game proposal.
  # This method takes into account the roles the user has for the group the game proposal belongs to.
  #
  # @param game_proposal [GameProposal] the game proposal to check roles for
  # @return [Role] the highest role the user has for the game proposal
  def highest_role_for_game_proposal(game_proposal)
    highest_role = most_permissive_role_for_resource(game_proposal)

    # roles for game proposals can be superseded by roles for the group
    highest_group_role = most_permissive_role_for_resource(game_proposal.group)
    highest_role = highest_group_role if RoleHierarchy.supersedes?(highest_group_role, highest_role)
    highest_role
  end

  def supersedes_user_in_group?(role_user, group)
    RoleHierarchy.supersedes?(most_permissive_role_for_resource(group), role_user.most_permissive_role_for_resource(group))
  end

  # Returns the highest role a user has for a particular resource.
  def most_permissive_role_for_resource(resource)
    roles.where(resource: resource).min_by { |role| RoleHierarchy.role_weight(role) }
  end

  def most_permissive_role_weight_for_resource(resource)
    roles.where(resource: resource).map { |role| RoleHierarchy.role_weight(role) }.min || 1000
  end

  def update_roles(add_roles: [], remove_roles: [])
    RoleUpdateService.call(self, add_roles, remove_roles)
  end

  def membership_for_group(group)
    group_memberships.find_by(group: group, user: self)
  end

  def get_vote_for_proposal(proposal)
    proposal_votes.find_by(game_proposal: proposal)
  end

  def nearest_proposal_availability(game_proposal)
    availabilities = game_proposal.proposal_availabilities.for_user(self)
    if availabilities.empty?
      nearest_group_availability(game_proposal.group)
    else
      availabilities.first.availability
    end
  end

  def make_sole_user_permission_set(resource)
    raise ArgumentError, "No resource provided for user (#{user.username}) permission set." if resource.nil?
    resource.make_permission_set([self])
  end

  def nearest_group_availability(group)
    availabilities = group.group_availabilities.for_user(self)
    if availabilities.empty?
      user_availability.availability
    else
      availabilities.first.availability
    end
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

  def upcoming_game_sessions
    game_sessions.where("date >= ?", Time.current)
  end

  def pending_game_proposals
    game_proposals.reject { |proposal| proposal.user_voted_yes_or_no?(self) }.sort_by(&:created_at)
  end

  def pending_game_proposal_count
    pending_game_proposals.count
  end

  def groups_user_can_create_proposal_for
    groups.select { |group| GroupPolicy.new(self, group).create_game_proposal? }
  end

  def broadcast_role_change_for_resource(resource)
    Turbo::Streams::ActionBroadcastJob.perform_later(
      "user_roles_#{id}_#{resource.class.name.underscore}_#{resource.id}",
      action: :update,
      method: :morph,
      target: nil,
      targets: ".user_roles_#{id}_#{resource.class.name.underscore}_#{resource.id}",
      partial: "#{resource.class.name.underscore.pluralize}/roles",
      locals: {"#{resource.class.name.underscore}_roles": roles_for_resource(resource).to_a}
    )
  end

  def has_any_role_for_resource?(roles_to_check, resource)
    roles_to_check.any? { |role| has_cached_role?(role, resource) }
  end

  def clear_email_from_other_users
    return unless verified? && email.present?

    # Find users with the same email who are not this user
    User.where(email: email)
      .where.not(id: id)
      .update_all(email: nil)
  end
end
