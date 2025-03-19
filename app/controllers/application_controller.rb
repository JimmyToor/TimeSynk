class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :set_current_request_details
  before_action :authenticate
  before_action :check_maintenance_mode

  after_action :verify_policy_scoped, only: :index
  after_action :verify_authorized, except: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def authenticate
    if (session_record = Session.find_by_id(cookies.signed[:session_token]))
      Current.session = session_record
    else
      redirect_to sign_in_path
    end
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def pundit_user
    Current.user
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to request.referrer || root_path
  end

  def check_maintenance_mode
    return unless Current.user
    return if Current.user&.has_role?(:site_admin) || request.path == sign_in_path || request.path == sign_out_path

    if ENV.fetch("MAINTENANCE_MODE", "false") == "true"
      render "home/maintenance", layout: "guest", status: :service_unavailable
    end
  end
end
