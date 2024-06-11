class User < ApplicationRecord
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
  has_many :game_proposals, dependent: :destroy
  has_many :game_sessions, dependent: :destroy
  has_many :game_session_attendances, dependent: :destroy
  has_many :proposal_votes, dependent: :destroy
  has_many :user_availabilities, dependent: :destroy
  has_many :group_availabilities, dependent: :destroy
  has_many :proposal_availabilities, dependent: :destroy
  has_many :default_availability_schedules, through: :user_availabilities, source: :schedule
  has_many :group_availability_schedules, through: :group_availabilities, source: :schedule
  has_many :proposal_availability_schedules, through: :proposal_availabilities, source: :schedule

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, allow_nil: true, length: {minimum: 12}

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account = Account.new
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def schedules_for_group(group)
    group_availability_schedules.where(group_availabilities: {group: group})
  end

  def schedules_for_proposal(proposal)
    proposal_availability_schedules.where(proposal_availabilities: {proposal: proposal})
  end
end
