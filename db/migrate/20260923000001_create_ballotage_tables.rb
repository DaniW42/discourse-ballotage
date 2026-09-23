# frozen_string_literal: true

class CreateBallotageTables < ActiveRecord::Migration[7.2]
  def change
    create_table :ballotage_ballots do |t|
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      # The tally is two bare counters with no reference to any user. Together with
      # ballotage_participations (who voted, no choice, no timestamps) this is the
      # whole secrecy model: nothing in the database links a member to a choice.
      t.integer :black_count, null: false, default: 0
      t.integer :white_count, null: false, default: 0
      t.integer :created_by_id, null: false
      t.datetime :cancelled_at
      t.datetime :finalized_at
      t.timestamps
    end

    add_index :ballotage_ballots, :ends_at

    # Deliberately no timestamps: a created_at per row, compared against the
    # ballot's counters, would help reconstruct individual votes.
    create_table :ballotage_participations do |t|
      t.integer :ballot_id, null: false
      t.integer :user_id, null: false
    end

    # One row per member and ballot: this is what makes a cast vote final.
    add_index :ballotage_participations, %i[ballot_id user_id], unique: true
  end
end
