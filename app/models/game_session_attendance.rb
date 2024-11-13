class GameSessionAttendance < ApplicationRecord
  belongs_to :game_session, touch: true
  belongs_to :user
end
