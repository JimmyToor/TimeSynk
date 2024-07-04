# frozen_string_literal: true

# A service object that creates a new group and adds the creator as a member.
class GroupCreationService
  def initialize(params, user)
    @params = params
    @user = user
  end

  # Creates a new group and adds the creator as a member.
  #
  # @return [Group] The newly created group.
  def create_group_and_membership
    ActiveRecord::Base.transaction do
      @group = Group.new(@params)
      @group.save!
      @group.users << Current.user
      @user.add_role :owner, @group
    end
    @group
  rescue ActiveRecord::RecordInvalid => e
    @group.errors.add(:base, e.message)
    @group
  end
end
