class CreateGameSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :game_sessions do |t|
      t.references :game_proposal, null: false, foreign_key: true
      t.datetime :date
      t.interval :duration

      t.timestamps
    end
  end
end
