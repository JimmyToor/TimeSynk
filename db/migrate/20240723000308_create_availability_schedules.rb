class CreateAvailabilitySchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_schedules do |t|
      t.references :availability, null: false, foreign_key: true
      t.references :schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
