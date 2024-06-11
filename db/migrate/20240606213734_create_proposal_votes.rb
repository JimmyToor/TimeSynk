class CreateProposalVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :proposal_votes do |t|
      t.references :game_proposal, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :yes_vote
      t.text :comment

      t.timestamps
    end
  end
end
