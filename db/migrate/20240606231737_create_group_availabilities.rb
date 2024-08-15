class CreateGroupAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :group_availabilities do |t|
      t.references :availability, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
