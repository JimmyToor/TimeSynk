class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"

    create_table :users do |t|
      t.citext :email, null: true
      t.citext :username, null: false, index: {unique: true}
      t.string :password_digest, null: false
      t.string :timezone, null: false, default: "UTC"

      t.boolean :verified, null: false, default: false

      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
    add_index :users, :email, unique: true, where: "email IS NOT NULL AND email <> '' AND verified = true"
  end
end
