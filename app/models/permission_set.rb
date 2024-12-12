class PermissionSet
  include ActiveModel::API

  # users_roles is a hash of user_id keys and any values
  attr_accessor :resource, :users_roles

  def initialize(resource:, users_roles: {})
    @resource = resource
    @users_roles = users_roles
  end
end
