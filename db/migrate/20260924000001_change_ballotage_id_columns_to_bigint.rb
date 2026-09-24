# frozen_string_literal: true

# Discourse is moving user ids to bigint (its CI already starts user ids above
# the 32-bit range), so every column referencing a user or ballot id is bigint.
class ChangeBallotageIdColumnsToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :ballotage_participations, :user_id, :bigint
    change_column :ballotage_participations, :ballot_id, :bigint
    change_column :ballotage_ballots, :created_by_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
