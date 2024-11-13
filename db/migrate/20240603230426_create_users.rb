class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email,           null: true
      t.string :username, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :timezone, null: false, default: "UTC"

      t.boolean :verified, null: false, default: false

      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL AND email <> ''"
  end
end
