class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.bigint :igdb_id
      t.text :name, null: false
      t.text :cover_image_url
      t.text :platforms, array: true, null: false, default: []
      t.text :igdb_url
      t.date :release_date
      t.boolean :is_popular, default: false

      t.timestamps
    end
    add_index :games, :igdb_id, unique: true
    add_index :games, :name
  end
end
