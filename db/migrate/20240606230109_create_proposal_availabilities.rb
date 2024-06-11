class CreateProposalAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :proposal_availabilities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game_proposal, null: false, foreign_key: true
      t.references :schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
