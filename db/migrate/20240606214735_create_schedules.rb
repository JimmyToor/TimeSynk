class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.datetime :start_date, index: {unique: false}
      t.datetime :end_date, index: {unique: false}
      t.integer :duration
      t.text :schedule_pattern

      t.timestamps
    end
  end
end
