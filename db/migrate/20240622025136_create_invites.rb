class CreateInvites < ActiveRecord::Migration[7.1]
  def change
    create_table :invites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.string :invite_token, null: false
      t.bigint :role_ids, array: true, null: false, default: []
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :invites, :invite_token, unique: true
  end
end
