require "rails_helper"

RSpec.describe FoundingStarterPackParser do
  WELL_FORMED_RESPONSE = <<~TEXT
    === ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===
    > DRAFT FOR LAWYER REVIEW.

    ## Likely shared values
    The team values democratic ownership.

    === ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===
    > DRAFT FOR LAWYER REVIEW.

    ## Customer Segments
    Mission-driven nonprofits.

    === ARTIFACT 3: LEGAL FORM COMPARISON ===
    > DRAFT FOR LAWYER REVIEW.

    ## Worker Cooperative
    Governance: one member, one vote.

    === OPEN QUESTIONS ===
    > Three questions.

    1. What is the minimum capital contribution?
    2. How will exit mechanics work?
    3. Who holds the deciding vote on new members?
  TEXT

  def parse(text)
    described_class.parse(text)
  end

  # ── Well-formed input ────────────────────────────────────────────────────────

  describe "well-formed input" do
    subject(:result) { parse(WELL_FORMED_RESPONSE) }

    it "returns non-nil values for all four fields" do
      expect(result.conversation_summary).not_to be_nil
      expect(result.business_model_canvas).not_to be_nil
      expect(result.legal_form_comparison).not_to be_nil
      expect(result.open_questions).not_to be_nil
    end

    it "includes the DRAFT FOR LAWYER REVIEW banner in conversation_summary" do
      expect(result.conversation_summary).to include("DRAFT FOR LAWYER REVIEW")
    end

    it "includes the numbered questions in open_questions" do
      expect(result.open_questions).to include("1.")
      expect(result.open_questions).to include("2.")
      expect(result.open_questions).to include("3.")
    end

    it "does not bleed one section's delimiter into another section's content" do
      expect(result.conversation_summary).not_to include("ARTIFACT 2")
      expect(result.business_model_canvas).not_to include("ARTIFACT 3")
      expect(result.legal_form_comparison).not_to include("OPEN QUESTIONS")
    end
  end

  # ── Whitespace tolerance ─────────────────────────────────────────────────────

  describe "whitespace tolerance" do
    it "parses correctly with extra spaces around === markers" do
      text = WELL_FORMED_RESPONSE.gsub("===", "===  ")
      result = parse(text)
      expect(result.conversation_summary).not_to be_nil
      expect(result.open_questions).not_to be_nil
    end

    it "strips leading and trailing whitespace from each section" do
      result = parse(WELL_FORMED_RESPONSE)
      expect(result.conversation_summary).to eq(result.conversation_summary.strip)
      expect(result.open_questions).to eq(result.open_questions.strip)
    end
  end

  # ── Case tolerance ───────────────────────────────────────────────────────────

  describe "case tolerance" do
    it "parses lowercase delimiters correctly" do
      text = WELL_FORMED_RESPONSE
               .gsub("=== ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===",
                     "=== artifact 1: founding conversation summary ===")
               .gsub("=== ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===",
                     "=== artifact 2: cooperative business model canvas ===")
               .gsub("=== ARTIFACT 3: LEGAL FORM COMPARISON ===",
                     "=== artifact 3: legal form comparison ===")
               .gsub("=== OPEN QUESTIONS ===", "=== open questions ===")
      result = parse(text)
      expect(result.conversation_summary).not_to be_nil
      expect(result.open_questions).not_to be_nil
    end
  end

  # ── Missing OPEN QUESTIONS delimiter ────────────────────────────────────────

  describe "missing OPEN QUESTIONS delimiter" do
    let(:text_without_open_questions) do
      WELL_FORMED_RESPONSE.lines.reject { |l| l.include?("OPEN QUESTIONS") }.join
    end

    it "returns nil for open_questions" do
      expect(parse(text_without_open_questions).open_questions).to be_nil
    end

    it "still returns the other three sections" do
      result = parse(text_without_open_questions)
      expect(result.conversation_summary).not_to be_nil
      expect(result.business_model_canvas).not_to be_nil
      expect(result.legal_form_comparison).not_to be_nil
    end

    it "does not raise" do
      expect { parse(text_without_open_questions) }.not_to raise_error
    end
  end

  # ── All delimiters missing ───────────────────────────────────────────────────

  describe "no delimiters present" do
    let(:plain_text) { "This is just some text with no delimiters at all." }

    it "returns nil for all four fields" do
      result = parse(plain_text)
      expect(result.conversation_summary).to be_nil
      expect(result.business_model_canvas).to be_nil
      expect(result.legal_form_comparison).to be_nil
      expect(result.open_questions).to be_nil
    end

    it "does not raise" do
      expect { parse(plain_text) }.not_to raise_error
    end
  end

  # ── Empty and nil input ──────────────────────────────────────────────────────

  it "returns all nil fields for an empty string" do
    result = parse("")
    expect(result.conversation_summary).to be_nil
    expect(result.open_questions).to be_nil
  end

  it "returns all nil fields for nil input" do
    result = parse(nil)
    expect(result.conversation_summary).to be_nil
    expect(result.open_questions).to be_nil
  end

  it "does not raise on empty string" do
    expect { parse("") }.not_to raise_error
  end

  it "does not raise on nil" do
    expect { parse(nil) }.not_to raise_error
  end
end
