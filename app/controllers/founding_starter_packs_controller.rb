class FoundingStarterPacksController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: [:create]

  LEGAL_FORM_LABELS = {
    "worker_coop"            => "Worker Cooperative",
    "multi_stakeholder_coop" => "Multi-Stakeholder Cooperative",
    "employee_owned_llc"     => "Employee-Owned LLC",
    "benefit_corporation"    => "Benefit Corporation",
    "unsure"                 => "Unsure"
  }.freeze

  def create
    @community = current_user.working_communities.find(params[:working_community_id])

    raw    = GeminiService.generate(
      template:  "collectivestart_starter_pack_v1",
      variables: variables_for(@community)
    )
    parsed = FoundingStarterPackParser.parse(raw)

    unless parsed.conversation_summary && parsed.business_model_canvas &&
           parsed.legal_form_comparison && parsed.open_questions
      raise GeminiService::GeminiError, "Incomplete response — not all artifacts were generated."
    end

    pack   = @community.founding_starter_pack || @community.build_founding_starter_pack

    pack.update!(
      conversation_summary:  parsed.conversation_summary,
      business_model_canvas: parsed.business_model_canvas,
      legal_form_comparison: parsed.legal_form_comparison,
      open_questions:        parsed.open_questions,
      gemini_raw:            raw,
      generated_at:          Time.current
    )

    render turbo_stream: turbo_stream.update(
      "starter-pack-section",
      partial: "working_communities/starter_pack",
      locals:  { community: @community, pack: pack }
    )

  rescue GeminiService::GatekeeperError
    render_ai_error(:gatekeeper_blocked)
  rescue GeminiService::BudgetExceededError
    render_ai_error(:budget_exceeded)
  rescue GeminiService::TimeoutError
    render_ai_error(:timeout)
  rescue GeminiService::GeminiError
    render_ai_error(:error)
  end

  private

  def variables_for(community)
    {
      community_name:        community.name,
      jurisdiction:          community.jurisdiction,
      founding_team_size:    community.founding_team_size.to_s,
      legal_form_preference: LEGAL_FORM_LABELS.fetch(community.legal_form_preference, community.legal_form_preference),
      purpose:               community.purpose,
      business_model:        community.business_model
    }
  end

  def render_ai_error(error_type)
    render turbo_stream: turbo_stream.update(
      "starter-pack-section",
      partial: "working_communities/generation_error",
      locals:  { error_type: error_type, community: @community }
    )
  end
end
