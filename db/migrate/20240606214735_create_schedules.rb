class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :start_date, index: {unique: false}
      t.datetime :end_date, index: {unique: false}
      t.interval :duration
      t.jsonb :schedule_pattern, null: false, default: {}
      t.text :name, null: false, default: "New Schedule"
      t.text :description, null: true
      t.text :frequency, null: false, default: "Once"

      t.timestamps
    end
  end
end
