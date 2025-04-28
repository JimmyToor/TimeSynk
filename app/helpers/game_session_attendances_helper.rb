module GameSessionAttendancesHelper
  def format_attendance(attendance)
    case attendance
    when true
      "Yes"
    when false
      "No"
    else
      "Unsure"
    end
  end
end
