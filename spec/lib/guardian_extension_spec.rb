# frozen_string_literal: true

RSpec.describe Ballotage::GuardianExtension do
  fab!(:voting_group, :group)
  fab!(:oversight_group, :group)
  fab!(:voter) { Fabricate(:user, group_ids: [voting_group.id]) }
  fab!(:overseer) { Fabricate(:user, group_ids: [oversight_group.id]) }
  fab!(:plain_user, :user)
  fab!(:admin)

  before do
    SiteSetting.ballotage_enabled = true
    SiteSetting.ballotage_voting_group = voting_group.id.to_s
    SiteSetting.ballotage_oversight_group = oversight_group.id.to_s
  end

  describe "#can_vote_in_ballotage?" do
    it "is true for a member of the voting group" do
      expect(Guardian.new(voter).can_vote_in_ballotage?).to eq(true)
    end

    it "is false for a user outside the voting group" do
      expect(Guardian.new(plain_user).can_vote_in_ballotage?).to eq(false)
    end

    it "is false for an admin who is not in the voting group" do
      expect(Guardian.new(admin).can_vote_in_ballotage?).to eq(false)
    end

    it "is false for an anonymous guardian" do
      expect(Guardian.new.can_vote_in_ballotage?).to eq(false)
    end

    it "is false when no voting group is configured" do
      SiteSetting.ballotage_voting_group = ""
      expect(Guardian.new(voter).can_vote_in_ballotage?).to eq(false)
    end
  end

  describe "#can_oversee_ballotage?" do
    it "is true for an admin" do
      expect(Guardian.new(admin).can_oversee_ballotage?).to eq(true)
    end

    it "is true for a member of the oversight group" do
      expect(Guardian.new(overseer).can_oversee_ballotage?).to eq(true)
    end

    it "is false for a plain user" do
      expect(Guardian.new(plain_user).can_oversee_ballotage?).to eq(false)
    end

    it "is false for a voter who is not in the oversight group" do
      expect(Guardian.new(voter).can_oversee_ballotage?).to eq(false)
    end

    it "is false for an anonymous guardian" do
      expect(Guardian.new.can_oversee_ballotage?).to eq(false)
    end
  end

  describe "#can_manage_ballotage?" do
    it "is true for an admin regardless of the oversight_can_manage setting" do
      SiteSetting.ballotage_oversight_can_manage = false
      expect(Guardian.new(admin).can_manage_ballotage?).to eq(true)
    end

    it "is true for an oversight group member when ballotage_oversight_can_manage is enabled" do
      SiteSetting.ballotage_oversight_can_manage = true
      expect(Guardian.new(overseer).can_manage_ballotage?).to eq(true)
    end

    it "is false for an oversight group member when ballotage_oversight_can_manage is disabled" do
      SiteSetting.ballotage_oversight_can_manage = false
      expect(Guardian.new(overseer).can_manage_ballotage?).to eq(false)
    end

    it "is false for a plain user even when ballotage_oversight_can_manage is enabled" do
      SiteSetting.ballotage_oversight_can_manage = true
      expect(Guardian.new(plain_user).can_manage_ballotage?).to eq(false)
    end

    it "is false for an anonymous guardian" do
      SiteSetting.ballotage_oversight_can_manage = true
      expect(Guardian.new.can_manage_ballotage?).to eq(false)
    end
  end
end
