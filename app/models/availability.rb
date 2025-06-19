class Availability < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    against: [:name, :description],
    using: {tsearch: {prefix: true}}
  belongs_to :user
  has_many :availability_schedules, dependent: :destroy, inverse_of: :availability
  has_many :schedules, through: :availability_schedules
  has_one :user_availability, inverse_of: :availability
  has_many :group_availabilities, inverse_of: :availability, dependent: :destroy
  has_many :proposal_availabilities, inverse_of: :availability, dependent: :destroy

  accepts_nested_attributes_for :availability_schedules, allow_destroy: true, reject_if: :all_blank

  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.squish }

  validates :name, presence: true, length: {maximum: 300}, uniqueness: {scope: :user}
  validates :description, length: {maximum: 300}
  validates :user, presence: true

  before_destroy :prevent_destroying_last_availability, :transfer_user_availability_if_default

  after_commit :notify_calendars

  DEFAULT_PARAMS = {
    name: "New Availability",
    description: ""
  }.freeze

  def username
    user.username
  end

  private

  def prevent_destroying_last_availability
    if user.availabilities.count <= 1
      errors.add(:base, I18n.t("availability.destroy.only_availability"))
      throw(:abort)
    end
  end

  def transfer_user_availability_if_default
    return unless user_availability.present?

    fallback_availability = user.availabilities.where.not(id: id).first
    user.user_availability.update!(availability: fallback_availability)
  end

  # For any groups or game proposals that this availability is associated with, notify their calendars that a refresh is needed.
  def notify_calendars
    notified_proposals = Set.new

    # Groups that directly use this availability
    groups = group_availabilities.map(&:group)
    # Groups that use this availability as a fallback
    groups += (user.groups - groups).select { |group| group.get_user_group_availability(user).nil? } if user_availability.present?

    groups.each do |group|
      group.notify_calendar_update(false)

      # Game Proposals that fall back to this availability through the group
      group.game_proposals.select { |proposal| proposal.get_user_proposal_availability(user).nil? }.each do |game_proposal|
        game_proposal.notify_calendar_update(false)
        notified_proposals.add(game_proposal.id)
      end
    end

    # Proposals that directly use this availability
    proposal_availabilities.map(&:game_proposal).each do |proposal|
      proposal.notify_calendar_update(false) unless notified_proposals.include?(proposal.id)
    end
  end
end
