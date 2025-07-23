module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if (session_record = Session.find_by_id(cookies.signed[:session_token]))
        session_record.user
      else
        reject_unauthorized_connection
      end
    rescue ActiveRecord::RecordNotFound
      reject_unauthorized_connection
    end
  end
end
