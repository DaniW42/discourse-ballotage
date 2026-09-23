# frozen_string_literal: true

module Ballotage
  # Records THAT a member voted in a ballot — never what they voted.
  class Participation < ActiveRecord::Base
    self.table_name = "ballotage_participations"

    belongs_to :ballot, class_name: "Ballotage::Ballot"
    belongs_to :user
  end
end
