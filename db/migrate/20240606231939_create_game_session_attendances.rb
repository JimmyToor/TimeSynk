class CreateGameSessionAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :game_session_attendances do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :attending

      t.timestamps
    end
  end
end
