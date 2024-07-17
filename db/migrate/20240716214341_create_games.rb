class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games, id:false do |t|
      t.bigint :id, primary_key: true
      t.text :name, null: false
      t.text :cover_image_url
      t.text :platforms, array: true, null: false, default: []
      t.text :igdb_url
      t.date :release_date

      t.timestamps
    end
    add_index :games, :name
  end
end
