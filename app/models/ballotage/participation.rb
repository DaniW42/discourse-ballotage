# frozen_string_literal: true

module Ballotage
  # Records THAT a member voted in a ballot — never what they voted.
  class Participation < ActiveRecord::Base
    self.table_name = "ballotage_participations"

    belongs_to :ballot, class_name: "Ballotage::Ballot"
    belongs_to :user
  end
end

# == Schema Information
#
# Table name: ballotage_participations
#
#  id        :bigint           not null, primary key
#  ballot_id :integer          not null
#  user_id   :integer          not null
#
# Indexes
#
#  index_ballotage_participations_on_ballot_id_and_user_id  (ballot_id,user_id) UNIQUE
#
