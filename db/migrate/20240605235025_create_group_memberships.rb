class CreateGroupMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :is_admin, null: false, default: false

      t.timestamps
    end
  end
end
