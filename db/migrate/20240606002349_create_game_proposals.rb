class CreateGameProposals < ActiveRecord::Migration[7.1]
  def change
    create_table :game_proposals do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :game_id
      t.integer :yes_votes
      t.integer :no_votes

      t.timestamps
    end
  end
end
