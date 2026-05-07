# Phase 5 — Founding Starter Pack Generation

**Goal:** Users can generate (and regenerate) a Founding Starter Pack. Gemini is called via `GeminiService`. The result is delivered inline via Turbo Stream. Tabs work with URL sync. All error states are handled. Rate limiting is applied.

**Depends on:** Phase 2 (models), Phase 3 (CRUD and show page with `id="starter-pack-section"`), Phase 4 (AiTemplate seeded, parser service exists).

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §5–6, §8

**Reference docs to read first:**
- `docs/turbo-stimulus-patterns.md` — Turbo Stream patterns, Stimulus tab and URL sync
- `docs/ai-templates.md` — GeminiService.generate call signature, error classes
- `docs/ai-guardrails.md` — Budget, gatekeeper, timeout errors and how to rescue them
- `CLAUDE.md` — "ALWAYS update(), NEVER replace()" for Turbo Streams

---

## Context

**Turbo Stream rule:** The response to the generate POST is always a Turbo Stream. Use `turbo_stream.update("starter-pack-section", ...)` — never `replace`. The `id="starter-pack-section"` div is already on the show page from Phase 3.

**Error handling:** Rescue all `GeminiService::GeminiError` subclasses. Each renders the boilerplate's `shared/ai_error` partial via Turbo Stream update to the same `starter-pack-section` div, plus a "Try again" button that resubmits the same `POST`.

**Regeneration:** If a `FoundingStarterPack` already exists, update all fields in place. Never create a second record.

---

## 1. `FoundingStarterPacksController`

`app/controllers/founding_starter_packs_controller.rb`:

```ruby
class FoundingStarterPacksController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: [:create]

  LEGAL_FORM_LABELS = {
    "worker_coop"             => "Worker Cooperative",
    "multi_stakeholder_coop"  => "Multi-Stakeholder Cooperative",
    "employee_owned_llc"      => "Employee-Owned LLC",
    "benefit_corporation"     => "Benefit Corporation",
    "unsure"                  => "Unsure"
  }.freeze

  def create
    @community = current_user.working_communities.find(params[:working_community_id])

    raw = GeminiService.generate(
      template:  "collectivestart_starter_pack_v1",
      variables: variables_for(@community)
    )

    parsed = FoundingStarterPackParser.parse(raw)
    pack   = @community.founding_starter_pack || @community.build_founding_starter_pack

    pack.update!(
      conversation_summary:  parsed.conversation_summary,
      business_model_canvas: parsed.business_model_canvas,
      legal_form_comparison: parsed.legal_form_comparison,
      open_questions:        parsed.open_questions,
      gemini_raw:            raw,
      generated_at:          Time.current
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "starter-pack-section",
          partial: "working_communities/starter_pack",
          locals:  { community: @community, pack: pack }
        )
      end
    end

  rescue GeminiService::GatekeeperError => e
    render_ai_error(:gatekeeper_blocked)
  rescue GeminiService::BudgetExceededError => e
    render_ai_error(:budget_exceeded)
  rescue GeminiService::TimeoutError => e
    render_ai_error(:timeout)
  rescue GeminiService::GeminiError => e
    render_ai_error(:error)
  end

  private

  def variables_for(community)
    {
      community_name:       community.name,
      jurisdiction:         community.jurisdiction,
      founding_team_size:   community.founding_team_size.to_s,
      legal_form_preference: LEGAL_FORM_LABELS.fetch(community.legal_form_preference, community.legal_form_preference),
      purpose:              community.purpose,
      business_model:       community.business_model
    }
  end

  def render_ai_error(error_type)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "starter-pack-section",
          partial: "working_communities/generation_error",
          locals:  { error_type: error_type, community: @community }
        )
      end
    end
  end
end
```

---

## 2. `markdown` Helper

In `app/helpers/application_helper.rb`, add:

```ruby
def markdown(text)
  return "" if text.blank?
  renderer = Redcarpet::Render::HTML.new(safe_links_only: true, no_images: true)
  Redcarpet::Markdown.new(renderer, autolink: true, tables: false).render(text).html_safe
end
```

Verify `redcarpet` is in `Gemfile`. The boilerplate includes it for the admin template editor preview — check before adding.

---

## 3. Update Show Page for Pack-Present State

Update `app/views/working_communities/show.html.erb`. Keep the lawyer-review alert and header from Phase 3. Replace the `starter-pack-section` div content with conditional rendering:

```erb
<div id="starter-pack-section">
  <% if @community.founding_starter_pack %>
    <%= render "starter_pack", community: @community, pack: @community.founding_starter_pack %>
  <% else %>
    <%= render "empty_pack_state", community: @community %>
  <% end %>
</div>
```

Also update the action toolbar button to say "Regenerate Starter Pack" when a pack exists:

```erb
<%= button_to @community.founding_starter_pack ? "Regenerate Starter Pack" : "Generate Starter Pack",
      working_community_founding_starter_pack_path(@community),
      method: :post,
      class: "btn btn-primary btn-sm",
      data: { turbo_stream: true } %>
```

---

## 4. Starter Pack Partial

`app/views/working_communities/_starter_pack.html.erb`:

```erb
<%# Tab navigation %>
<ul class="nav nav-tabs mb-3" data-controller="tab-url-sync" role="tablist">
  <li class="nav-item" role="presentation">
    <button class="nav-link active" id="tab-conversation"
            data-bs-toggle="tab" data-bs-target="#pane-conversation"
            data-tab-url-sync-key-param="conversation_summary"
            type="button" role="tab">Founding Conversation</button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="tab-canvas"
            data-bs-toggle="tab" data-bs-target="#pane-canvas"
            data-tab-url-sync-key-param="business_model_canvas"
            type="button" role="tab">Business Model Canvas</button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="tab-legal"
            data-bs-toggle="tab" data-bs-target="#pane-legal"
            data-tab-url-sync-key-param="legal_form_comparison"
            type="button" role="tab">Legal Form Comparison</button>
  </li>
</ul>

<%# Tab content %>
<div class="tab-content starter-pack-tab-content">
  <div class="tab-pane fade show active" id="pane-conversation" role="tabpanel">
    <% if pack.conversation_summary.present? %>
      <%= markdown(pack.conversation_summary) %>
    <% else %>
      <div class="alert alert-warning">This section did not parse cleanly. Open the raw response below to see it, or regenerate.</div>
    <% end %>
  </div>
  <div class="tab-pane fade" id="pane-canvas" role="tabpanel">
    <% if pack.business_model_canvas.present? %>
      <%= markdown(pack.business_model_canvas) %>
    <% else %>
      <div class="alert alert-warning">This section did not parse cleanly. Open the raw response below to see it, or regenerate.</div>
    <% end %>
  </div>
  <div class="tab-pane fade" id="pane-legal" role="tabpanel">
    <% if pack.legal_form_comparison.present? %>
      <%= markdown(pack.legal_form_comparison) %>
    <% else %>
      <div class="alert alert-warning">This section did not parse cleanly. Open the raw response below to see it, or regenerate.</div>
    <% end %>
  </div>
</div>

<%# Open Questions %>
<% if pack.open_questions.present? %>
  <div class="alert alert-info mt-4">
    <strong>Open Questions</strong>
    <%= markdown(pack.open_questions) %>
  </div>
<% end %>

<%# Raw response toggle %>
<div class="mt-4">
  <a class="btn btn-link btn-sm p-0" data-bs-toggle="collapse" href="#raw-response">
    Show raw response
  </a>
  <div class="collapse mt-2" id="raw-response">
    <pre class="p-3 bg-dark border rounded" style="white-space: pre-wrap; font-size: 0.8rem;"><%= pack.gemini_raw %></pre>
  </div>
</div>

<%# Footer %>
<p class="text-muted small mt-3">
  Generated <%= pack.generated_at&.strftime("%B %-d, %Y at %H:%M") %>.
  AI-generated content can be incorrect; verify before acting.
</p>
```

---

## 5. Empty Pack State Partial

`app/views/working_communities/_empty_pack_state.html.erb`:

```erb
<div class="card text-center py-5">
  <div class="card-body">
    <h5 class="card-title">No starter pack yet</h5>
    <p class="text-muted mb-4">
      Generate your Founding Starter Pack to get a founding conversation summary,
      a cooperative business model canvas, and a legal form comparison.
    </p>
    <%= button_to "Generate Starter Pack",
          working_community_founding_starter_pack_path(community),
          method: :post,
          class: "btn btn-primary",
          data: { turbo_stream: true } %>
  </div>
</div>
```

---

## 6. Generation Error Partial

`app/views/working_communities/_generation_error.html.erb`:

```erb
<%= render "shared/ai_error", error_type: error_type %>
<div class="mt-3">
  <%= button_to "Try again",
        working_community_founding_starter_pack_path(community),
        method: :post,
        class: "btn btn-outline-secondary",
        data: { turbo_stream: true } %>
</div>
```

---

## 7. Stimulus: `tab-url-sync` Controller

`app/javascript/controllers/tab_url_sync_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const params = new URLSearchParams(window.location.search)
    const active = params.get("tab")
    if (active) {
      const btn = this.element.querySelector(`[data-tab-url-sync-key-param="${active}"]`)
      if (btn) window.bootstrap.Tab.getOrCreateInstance(btn).show()
    }

    this.element.addEventListener("show.bs.tab", (event) => {
      const key = event.target.dataset.tabUrlSyncKeyParam
      if (!key) return
      const url = new URL(window.location)
      url.searchParams.set("tab", key)
      history.replaceState({}, "", url)
    })
  }
}
```

Register in `app/javascript/controllers/index.js`:

```javascript
import TabUrlSyncController from "./tab_url_sync_controller"
application.register("tab-url-sync", TabUrlSyncController)
```

---

## 8. CSS

Add to `app/assets/stylesheets/application.css`:

```css
.starter-pack-tab-content {
  max-width: 720px;
}

.starter-pack-tab-content .tab-pane {
  padding-top: 1.5rem;
  line-height: 1.7;
}
```

---

## RSpec Tests — Phase 5

**`spec/requests/founding_starter_packs_spec.rb`**

```ruby
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

  def post_generate
    post working_community_founding_starter_pack_path(community),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  # --- Auth ---
  it "redirects unauthenticated user" do
    post_generate
    expect(response).to redirect_to(sign_in_path)
  end

  it "returns 404 for non-owner community" do
    sign_in_as(user)
    other_community = create(:working_community, user: other)
    post working_community_founding_starter_pack_path(other_community),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:not_found)
  end

  # --- Success ---
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

    it "responds with a Turbo Stream updating starter-pack-section" do
      post_generate
      expect(response.body).to include("starter-pack-section")
      expect(response.content_type).to include("turbo-stream")
    end

    it "regenerating updates the existing pack in place" do
      create(:founding_starter_pack, working_community: community)
      expect { 2.times { post_generate } }.to change(FoundingStarterPack, :count).by(0)
      # count stays at 1 — second call updates, doesn't create
      expect(FoundingStarterPack.where(working_community: community).count).to eq(1)
    end
  end

  # --- Error states ---
  context "when Gemini raises GatekeeperError" do
    before do
      allow(GeminiService).to receive(:generate)
        .and_raise(GeminiService::GatekeeperError, "blocked")
      sign_in_as(user)
    end

    it "renders a Turbo Stream with an error message" do
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
      allow(GeminiService).to receive(:generate)
        .and_raise(GeminiService::BudgetExceededError, "over limit")
      sign_in_as(user)
    end

    it "renders a Turbo Stream error response" do
      post_generate
      expect(response.content_type).to include("turbo-stream")
    end
  end

  context "when Gemini raises TimeoutError" do
    before do
      allow(GeminiService).to receive(:generate)
        .and_raise(GeminiService::TimeoutError, "timed out")
      sign_in_as(user)
    end

    it "renders a Turbo Stream error response" do
      post_generate
      expect(response.content_type).to include("turbo-stream")
    end
  end
end
```

---

## Manual Checks — Phase 5

Run `rails server` in a separate terminal. Requires a valid `GEMINI_API_KEY` in `.env`.

- [ ] Open a working community → click "Generate Starter Pack" → pack appears inline without a full page reload (verify via browser network tab — should see a turbo-stream response)
- [ ] All three tabs display content rendered as HTML (markdown converted, not raw `##` symbols)
- [ ] "Open Questions" alert renders below the tabs
- [ ] "Show raw response" collapse reveals the `gemini_raw` text
- [ ] Footer shows generation timestamp
- [ ] Yellow lawyer-review alert is present on every tab visit
- [ ] Click "Business Model Canvas" tab → URL updates to `?tab=business_model_canvas`
- [ ] Reload page with `?tab=business_model_canvas` in URL → correct tab is active on load
- [ ] Click "Regenerate Starter Pack" → pack is updated in place; pack count in database stays at 1
- [ ] Test error state: set `GEMINI_API_KEY=invalid` in `.env`, restart server → click generate → error partial with "Try again" button appears in the same `starter-pack-section` div (no full page reload)
- [ ] Restore valid API key
