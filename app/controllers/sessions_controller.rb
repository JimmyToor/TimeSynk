class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[ new create ]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
    render layout: "guest"
  end

  def create
    user = User.authenticate_by(username: params[:username_or_email], password: params[:password]) ||
      User.authenticate_by(email: params[:username_or_email], password: params[:password])
    
    if user
      @session = user.sessions.create!
      cookies.signed.permanent[:session_token] = {value: @session.id, httponly: true}

      redirect_to root_path, notice: "Signed in successfully"
    else
      redirect_to sign_in_path(email_hint: params[:username_or_email]), alert: "That email or password is incorrect"
    end
  end

  def destroy
    @session.destroy
    cookies.delete(:session_token)
    redirect_to(sessions_path, notice: "That session has been logged out")
  end

  private

  def set_session
    @session = if params[:id]
      Current.user.sessions.find(params[:id])
    else
      Current.user.sessions.find_by(id: cookies.signed[:session_token])
    end
  end
end
