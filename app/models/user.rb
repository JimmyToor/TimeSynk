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
  has_many :groups, through: :group_memberships
  has_many :invites, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  has_many :game_proposals, dependent: :destroy
  has_many :game_sessions, dependent: :destroy
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


  validates :email, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :username, presence: true, uniqueness: true, length: {minimum: 3, maximum: 20}
  validates :password, allow_nil: true, length: {minimum: 8}


  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account = Account.new
  end

  after_create :assign_default_role

  after_create_commit :create_default_user_availability

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
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

  private

  def assign_default_role
    add_role(:newuser) if roles.blank?
  end

  def create_default_schedule
    schedule_pattern = IceCube::Rule.daily(1)
    Rails.logger.debug "Creating default schedule pattern: pattern: #{schedule_pattern}, pattern hash: #{schedule_pattern.to_hash}"
    schedules.create!(name: "Default Schedule",
                      start_date: Time.current.utc,
                      end_date: 10.years.from_now,
                      duration: 24.hours.to_i,
                      schedule_pattern: schedule_pattern
    )
  end

  def create_default_user_availability
    return unless user_availability.nil?

    schedule = create_default_schedule
    availability = schedule.availabilities.create!(name: "Default Availability", user: self)
    user_availability = UserAvailability.create!(user: self, availability: availability)
    self.user_availability = user_availability
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:user_availability, "could not be created: #{e.message}")
  end

  def avatar_type
    if avatar.attached? && !avatar.content_type.in?(%w(image/jpeg image/png image/gif))
      errors.add(:avatar, "must be a JPEG, PNG, or GIF")
    end
  end
end
