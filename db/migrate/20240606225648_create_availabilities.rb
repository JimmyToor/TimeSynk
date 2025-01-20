class CreateAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :availabilities do |t|
      t.references :user, null: false, foreign_key: true
      t.text :name, null: false, default: "New User Availability"
      t.text :description, null: false, default: ""

      t.timestamps
    end
  end
end
