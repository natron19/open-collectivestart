FactoryBot.define do
  factory :founding_starter_pack do
    association :working_community
    conversation_summary  { "## Likely Shared Values\nThe founding team prioritizes..." }
    business_model_canvas { "## Customer Segments\nMission-driven nonprofits..." }
    legal_form_comparison { "## Worker Cooperative\n**Governance structure:** One member, one vote..." }
    open_questions        { "1. How will the team handle a founding member who wants to exit?\n" \
                            "2. What is the minimum capital each member will contribute?\n" \
                            "3. How will the team recruit its first non-founding member?" }
    gemini_raw            { "=== ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===\n..." }
    generated_at          { Time.current }
  end
end
