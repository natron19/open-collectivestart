require "rails_helper"

RSpec.describe "FoundingStarterPacks", type: :request do
  let(:user)      { create(:user) }
  let(:other)     { create(:user) }
  let(:community) { create(:working_community, user: user) }

  let(:raw_response) do
    <<~TEXT
      === ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===
      > DRAFT FOR LAWYER REVIEW.
      Summary content here.

      === ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===
      > DRAFT FOR LAWYER REVIEW.
      Canvas content here.

      === ARTIFACT 3: LEGAL FORM COMPARISON ===
      > DRAFT FOR LAWYER REVIEW.
      Legal content here.

      === OPEN QUESTIONS ===
      1. Question one?
      2. Question two?
      3. Question three?
    TEXT
  end

  def post_generate(target_community = community)
    post working_community_founding_starter_pack_path(target_community),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  # ── Auth ─────────────────────────────────────────────────────────────────────

  it "redirects an unauthenticated user" do
    post_generate
    expect(response).to redirect_to(sign_in_path)
  end

  it "returns 404 for a non-owner community" do
    sign_in_as(user)
    other_community = create(:working_community, user: other)
    post working_community_founding_starter_pack_path(other_community),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:not_found)
  end

  # ── Success ───────────────────────────────────────────────────────────────────

  context "when Gemini succeeds" do
    before do
      allow(GeminiService).to receive(:generate).and_return(raw_response)
      sign_in_as(user)
    end

    it "calls GeminiService with the correct template name" do
      post_generate
      expect(GeminiService).to have_received(:generate)
        .with(hash_including(template: "collectivestart_starter_pack_v1"))
    end

    it "calls GeminiService with all six variables" do
      post_generate
      expect(GeminiService).to have_received(:generate).with(
        hash_including(variables: hash_including(
          :community_name, :jurisdiction, :founding_team_size,
          :legal_form_preference, :purpose, :business_model
        ))
      )
    end

    it "creates a FoundingStarterPack" do
      expect { post_generate }.to change(FoundingStarterPack, :count).by(1)
    end

    it "stores all four parsed fields" do
      post_generate
      pack = community.reload.founding_starter_pack
      expect(pack.conversation_summary).to include("Summary content")
      expect(pack.business_model_canvas).to include("Canvas content")
      expect(pack.legal_form_comparison).to include("Legal content")
      expect(pack.open_questions).to include("Question one")
    end

    it "stores gemini_raw" do
      post_generate
      expect(community.reload.founding_starter_pack.gemini_raw).to eq(raw_response)
    end

    it "sets generated_at" do
      post_generate
      expect(community.reload.founding_starter_pack.generated_at).to be_present
    end

    it "responds with a Turbo Stream targeting starter-pack-section" do
      post_generate
      expect(response.body).to include("starter-pack-section")
      expect(response.content_type).to include("turbo-stream")
    end

    it "updates the existing pack in place on regeneration" do
      create(:founding_starter_pack, working_community: community)
      post_generate
      post_generate
      expect(FoundingStarterPack.where(working_community: community).count).to eq(1)
    end
  end

  # ── Error states ──────────────────────────────────────────────────────────────

  context "when Gemini raises GatekeeperError" do
    before do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::GatekeeperError, "blocked")
      sign_in_as(user)
    end

    it "responds with a Turbo Stream targeting starter-pack-section" do
      post_generate
      expect(response.body).to include("starter-pack-section")
      expect(response.content_type).to include("turbo-stream")
    end

    it "does not create a FoundingStarterPack" do
      expect { post_generate }.not_to change(FoundingStarterPack, :count)
    end
  end

  context "when Gemini raises BudgetExceededError" do
    before do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::BudgetExceededError, "over limit")
      sign_in_as(user)
    end

    it "responds with a Turbo Stream" do
      post_generate
      expect(response.content_type).to include("turbo-stream")
    end
  end

  context "when Gemini raises TimeoutError" do
    before do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::TimeoutError, "timed out")
      sign_in_as(user)
    end

    it "responds with a Turbo Stream" do
      post_generate
      expect(response.content_type).to include("turbo-stream")
    end
  end
end
