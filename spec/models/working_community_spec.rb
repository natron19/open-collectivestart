require "rails_helper"

RSpec.describe WorkingCommunity, type: :model do
  subject(:community) { build(:working_community) }

  # ── Presence ────────────────────────────────────────────────────────────────

  describe "presence validations" do
    %i[name purpose jurisdiction business_model founding_team_size legal_form_preference].each do |attr|
      it "requires #{attr}" do
        community.send(:"#{attr}=", nil)
        expect(community).not_to be_valid
        expect(community.errors[attr]).to be_present
      end
    end
  end

  # ── Name length ─────────────────────────────────────────────────────────────

  describe "name length" do
    it "rejects a 1-character name" do
      community.name = "x"
      expect(community).not_to be_valid
    end

    it "accepts a 2-character name" do
      community.name = "xy"
      expect(community).to be_valid
    end

    it "accepts an 80-character name" do
      community.name = "a" * 80
      expect(community).to be_valid
    end

    it "rejects an 81-character name" do
      community.name = "a" * 81
      expect(community).not_to be_valid
    end
  end

  # ── Purpose length ───────────────────────────────────────────────────────────

  describe "purpose length" do
    it "rejects a 49-character purpose" do
      community.purpose = "a" * 49
      expect(community).not_to be_valid
    end

    it "accepts a 50-character purpose" do
      community.purpose = "a" * 50
      expect(community).to be_valid
    end
  end

  # ── Business model length ────────────────────────────────────────────────────

  describe "business_model length" do
    it "rejects a 49-character business_model" do
      community.business_model = "a" * 49
      expect(community).not_to be_valid
    end

    it "accepts a 50-character business_model" do
      community.business_model = "a" * 50
      expect(community).to be_valid
    end
  end

  # ── Founding team size ───────────────────────────────────────────────────────

  describe "founding_team_size" do
    it "rejects 1" do
      community.founding_team_size = 1
      expect(community).not_to be_valid
    end

    it "accepts 2" do
      community.founding_team_size = 2
      expect(community).to be_valid
    end

    it "accepts 50" do
      community.founding_team_size = 50
      expect(community).to be_valid
    end

    it "rejects 51" do
      community.founding_team_size = 51
      expect(community).not_to be_valid
    end

    it "rejects a float" do
      community.founding_team_size = 3.5
      expect(community).not_to be_valid
    end
  end

  # ── Legal form preference ────────────────────────────────────────────────────

  describe "legal_form_preference" do
    %w[worker_coop multi_stakeholder_coop employee_owned_llc benefit_corporation unsure].each do |value|
      it "accepts '#{value}'" do
        community.legal_form_preference = value
        expect(community).to be_valid
      end
    end

    it "rejects an invalid value" do
      community.legal_form_preference = "banana"
      expect(community).not_to be_valid
    end
  end

  # ── 25-community cap ─────────────────────────────────────────────────────────

  describe "25-community cap" do
    let(:user) { create(:user) }

    it "allows a 25th community" do
      create_list(:working_community, 24, user: user)
      community = build(:working_community, user: user)
      expect(community).to be_valid
    end

    it "rejects a 26th community with the correct message" do
      create_list(:working_community, 25, user: user)
      community = build(:working_community, user: user)
      expect(community).not_to be_valid
      expect(community.errors[:base]).to include("You can have at most 25 working communities.")
    end

    it "does not apply the cap on update" do
      create_list(:working_community, 25, user: user)
      existing = user.working_communities.first
      existing.name = "Updated Name"
      expect(existing).to be_valid
    end
  end

  # ── Associations ─────────────────────────────────────────────────────────────

  describe "associations" do
    it "is invalid without a user" do
      community.user = nil
      expect(community).not_to be_valid
    end

    it "destroys the founding_starter_pack when destroyed" do
      community = create(:working_community, :with_pack)
      pack_id = community.founding_starter_pack.id
      community.destroy
      expect(FoundingStarterPack.find_by(id: pack_id)).to be_nil
    end
  end
end
