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
  has_many :created_game_proposals, dependent: :destroy, class_name: "GameProposal", foreign_key: "user_id"
  has_many :game_sessions, dependent: :destroy, through: :game_proposals
  has_many :created_game_sessions, dependent: :destroy, class_name: "GameSession", foreign_key: "user_id"
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

  validate :avatar_type

  validates :email, uniqueness: { case_sensitive: false, allow_blank: true }, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :username, presence: true, uniqueness: true, length: {minimum: 3, maximum: 20}
  validates :password, allow_nil: true, length: {minimum: 8}


  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account = Account.new
  end

  after_create_commit :create_default_user_availability

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def roles_for_group(group)
    roles.where(resource: group)
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

    result = RoleHierarchy.supersedes?(highest_role, highest_role_user_role)

    Rails.logger.debug "USER #{username} SUPErSDES USER #{role_user.username} IN GAME PROPOSAL #{game_proposal.id}: #{result}"
    result
  end

  # Returns the highest role a user has for a particular game proposal.
  # This method takes into account the roles the user has for the group the game proposal belongs to.
  #
  # @param game_proposal [GameProposal] the game proposal to check roles for
  # @return [Role] the highest role the user has for the game proposal
  def highest_role_for_game_proposal(game_proposal)
    highest_role = highest_role_for_resource(game_proposal)

    # roles for game proposals can be superseded by roles for the group
    highest_group_role = highest_role_for_resource(game_proposal.group)
    highest_role = highest_group_role if RoleHierarchy.supersedes?(highest_group_role, highest_role)

    highest_role
  end

  def supersedes_user_in_group?(role_user, group)
    RoleHierarchy.supersedes?(highest_role_for_resource(group), role_user.highest_role_for_resource(group))
  end

  # Returns the highest role a user has for a particular resource.
  def highest_role_for_resource(resource)
    roles.where(resource: resource).min_by { |role| RoleHierarchy.role_weight(role) }
  end

  def membership_for_group(group)
    group_memberships.find_by(group: group, user: self)
  end

  def get_vote_for_proposal(proposal)
    proposal_votes.find_by(game_proposal: proposal)
  end

  def get_nearest_proposal_availability(game_proposal)
    availabilities = game_proposal.proposal_availabilities.for_user(self)
    if availabilities.empty?
      get_nearest_group_availability(game_proposal.group)
    else
      availabilities.first.availability
    end
  end

  def get_nearest_group_availability(group)
    availabilities = group.group_availabilities.for_user(self)
    if availabilities.empty?
      user_availability.availability
    else
      availabilities.first.availability
    end
  end

  def create_default_user_availability
    return unless user_availability.nil?

    schedule = create_default_schedule
    availability = schedule.availabilities.create!(name: "Default Availability", user: self)
    self.user_availability = UserAvailability.create!(user: self, availability: availability)
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:user_availability, "could not be created: #{e.message}")
  end

  def create_default_schedule
    schedule_pattern = IceCube::Rule.daily(1)
    schedules.create!(
      name: "Default Schedule",
      start_date: Time.current.utc,
      end_date: 10.years.from_now,
      duration: 24.hours.to_i,
      schedule_pattern: schedule_pattern
    )
  end

  def upcoming_game_sessions
    game_sessions.where("date >= ?", Time.current).sort_by(&:date)
  end
  
  def pending_game_proposals
    game_proposals.reject { |proposal| proposal.user_voted_yes_or_no?(self)}.sort_by(&:created_at)
  end

  def pending_game_proposal_count
    pending_game_proposals.count
  end

  private

  def avatar_type
    if avatar.attached? && !%w(image/jpeg image/png image/gif).include?(avatar.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or GIF")
    end
  end
end
