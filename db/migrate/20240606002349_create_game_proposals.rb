class CreateGameProposals < ActiveRecord::Migration[7.1]
  def change
    create_table :game_proposals do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :yes_votes_count, null: false, default: 0
      t.integer :no_votes_count, null: false, default: 0

      t.timestamps
    end
  end
end
