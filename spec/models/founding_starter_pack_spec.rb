require "rails_helper"

RSpec.describe FoundingStarterPack, type: :model do
  subject(:pack) { build(:founding_starter_pack) }

  # ── Presence & uniqueness ────────────────────────────────────────────────────

  it "is invalid without a working_community" do
    pack.working_community = nil
    expect(pack).not_to be_valid
    expect(pack.errors[:working_community]).to be_present
  end

  it "enforces uniqueness of working_community_id" do
    existing = create(:founding_starter_pack)
    duplicate = build(:founding_starter_pack, working_community: existing.working_community)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:working_community_id]).to be_present
  end

  # ── Optional parsed fields ───────────────────────────────────────────────────

  it "is valid with all four parsed fields nil when gemini_raw is present" do
    community = create(:working_community)
    pack = build(:founding_starter_pack, working_community: community,
                 conversation_summary: nil, business_model_canvas: nil,
                 legal_form_comparison: nil, open_questions: nil,
                 gemini_raw: "raw response text")
    expect(pack).to be_valid
  end

  # ── Through association ──────────────────────────────────────────────────────

  it "exposes the user through the working_community" do
    pack = create(:founding_starter_pack)
    expect(pack.user).to eq(pack.working_community.user)
  end

  # ── Cascade destroy ──────────────────────────────────────────────────────────

  it "is destroyed when its working_community is destroyed" do
    pack = create(:founding_starter_pack)
    community = pack.working_community
    community.destroy
    expect(FoundingStarterPack.find_by(id: pack.id)).to be_nil
  end
end
