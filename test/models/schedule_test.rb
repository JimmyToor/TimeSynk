require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "consolidate_occurrences returns empty array when no occurrences" do
    result = Schedule.consolidate_occurrences([])
    assert_equal [], result
  end

  test "consolidate_occurrences merges overlapping intervals" do
    start1 = Time.new(2000, 1, 1, 12, 0, 0)
    start2 = start1 + 30.minutes
    intervals = [
      Schedule::ScheduleInterval.new(start1, start1 + 1.hour),
      Schedule::ScheduleInterval.new(start2, start2 + 1.hour)
    ]

    result = Schedule.consolidate_occurrences(intervals)

    assert_equal 1, result.size
    assert_equal start1, result.first.start
    assert_equal start2 + 1.hour, result.first.end
  end

  test "consolidate_occurrences handles non overlapping intervals" do
    start1 = Time.new(2000, 1, 1, 12, 0, 0)
    start2 = start1 + 30.minutes
    start3 = Time.new(2000, 3, 1, 12, 0, 0)
    intervals = [
      Schedule::ScheduleInterval.new(start1, start1 + 1.hour),
      Schedule::ScheduleInterval.new(start2, start2 + 1.hour),
      Schedule::ScheduleInterval.new(start3, start3 + 1.hour)
    ]

    result = Schedule.consolidate_occurrences(intervals)

    assert_equal 2, result.size
    assert_equal start1, result.first.start
    assert_equal start2 + 1.hour, result.first.end
    assert_equal start3, result.last.start
    assert_equal start3 + 1.hour, result.last.end
  end

  test "consolidate_schedules returns empty array when no schedules" do
    result = Schedule.consolidate_schedules([], Time.current, Time.current + 1.day)
    assert_equal [], result
  end

  test "consolidate_schedules creates consolidated schedules" do
    start1 = Time.new(2000, 1, 1, 12, 0, 0)
    start2 = start1 + 30.minutes
    start3 = Time.new(2000, 1, 1, 15, 0, 0)

    schedule1 = Schedule.new(name: "Schedule 1", start_time: start1, end_time: start1 + 1.hour, duration: 1.hour, user_id: 1)
    schedule2 = Schedule.new(name: "Schedule 2", start_time: start2, end_time: start2 + 1.hour, duration: 1.hour, user_id: 1)
    # This schedule will not overlap with the others and should not be consolidated
    schedule3 = Schedule.new(name: "Schedule 3", start_time: start3, end_time: start3 + 1.hour, duration: 1.hour, user_id: 1)

    result = Schedule.consolidate_schedules([schedule1, schedule2, schedule3], start1, start3 + 1.week)

    # Schedules 1 and 2 overlap and should be consolidated
    assert_equal 2, result.size
    assert_equal start1, result.first.start_time
    assert_equal start2 + 1.hour, result.first.end_time
    # Schedule 3 should be unchanged
    assert_equal start3, result.last.start_time
    assert_equal start3 + 1.hour, result.last.end_time
  end

  test "find_overlaps returns empty array when no overlaps" do
    schedule1 = Schedule.new(name: "Schedule 1", start_time: Time.current, end_time: Time.current + 1.hour, duration: 1.hour, user_id: 1)
    schedule2 = Schedule.new(name: "Schedule 2", start_time: Time.current + 2.hours, end_time: Time.current + 3.hours, duration: 1.hour, user_id: 2)

    result = Schedule.find_overlaps([schedule1, schedule2], Time.current, Time.current + 1.day)

    assert_equal [], result
  end

  test "find_overlaps returns overlapping intervals" do
    start1 = Time.new(2000, 1, 1, 12, 0, 0, in: "+0000")
    start2 = start1 + 30.minutes
    start3 = Time.new(2000, 1, 1, 15, 0, 0, in: "+0000")

    schedule1 = Schedule.new(name: "Schedule 1", start_time: start1, end_time: start1 + 1.hour, duration: 1.hour, user_id: 1)
    schedule2 = Schedule.new(name: "Schedule 2", start_time: start2, end_time: start2 + 1.5.hours, duration: 1.5.hours, user_id: 2)
    schedule3 = Schedule.new(name: "Schedule 3", start_time: start3, end_time: start3 + 1.hour, duration: 1.hour, user_id: 2)

    result = Schedule.find_overlaps([schedule1, schedule2, schedule3], start1, schedule3.end_time)

    assert_equal [Schedule::ScheduleInterval.new(schedule2.start_time, schedule2.start_time + 30.minutes)], result
  end
end
