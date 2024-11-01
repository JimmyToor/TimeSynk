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
    @group = Group.new(@params)
    ActiveRecord::Base.transaction do
        @group.save!
        @group.users << @user
        @group.create_roles

        @user.add_role :owner, @group
    rescue ActiveRecord::RecordInvalid => e
        @group.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
    end
    @group
  end
end
