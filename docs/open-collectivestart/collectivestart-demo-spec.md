# CollectiveStart Demo - Spec

**Document Version:** 1.0
**Last Updated:** May 4, 2026
**Built on:** Open Demo Starter v2.0
**License:** MIT

---

## 1. App Overview

CollectiveStart Demo is a single-purpose Rails 8 app that helps a founding team think through what it would take to start a worker cooperative or other shared-ownership firm. The user describes their proposed working community in one form. The app returns a Founding Starter Pack: a synthesis of the team's likely founding conversation, a cooperative business model canvas, and a comparison of the legal forms most plausible for their situation.

The problem this addresses is that almost no one starts a co-op without first hitting an information wall. Conventional startup playbooks assume a corporation, a cap table, and an exit. Co-op founders need a different vocabulary (member-owners instead of shareholders, patronage instead of dividends, sociocratic governance instead of board control) and need it before they have hired a co-op attorney. The Founding Starter Pack gives them a starting draft to react to, not a finished document to file.

This is one tool from a larger multi-tenant SaaS suite the author is building called CollectiveStart, the operating system for forming and running working communities. The production app is multi-tenant with team collaboration, member onboarding, governance tooling, and an OWNERS health assessment loop. This demo isolates the founding engine: one team, one form, one comprehensive starter pack.

The demo is open source under MIT license, scoped to a single signed-in user, and runs locally. Visitors can clone the repo, set a Gemini API key, and have the app running in under five minutes. The AI prompt that generates the starter pack is editable in the admin panel without redeploying.

The indie hacker angle: forming a co-op is a long, paperwork-heavy domain that LLMs handle surprisingly well at the framing stage and surprisingly badly at the filing stage. The demo leans into the framing strength while structurally requiring every output to carry a "DRAFT FOR LAWYER REVIEW" banner so it cannot be mistaken for legal product.

---

## 2. Customizations Applied to the Boilerplate

| Area | Change |
|---|---|
| `.env.example` | `APP_NAME=CollectiveStart Demo`, `APP_TAGLINE=Tell me about your working community. Get your founding starter pack.`, `APP_DESCRIPTION=An open source demo of the CollectiveStart founding engine. Sketch a working community in one form, get a draft starter pack with three artifacts.` |
| `_accent.scss` | `--accent: #0f766e;` and `--accent-hover: #0d5e58;` |
| Navbar | Added one nav link "My Communities" pointing to `/working_communities`. Admin link visible to admin users only (boilerplate behavior). |
| `home/index.html.erb` | Replaced with the demo's landing pitch: hero with tagline, one paragraph explaining the founding starter pack, three preview cards for the three artifacts, and a "Sign up" CTA. |
| `dashboard/show.html.erb` | Replaced with a list of the user's working communities (most recent first) and a primary "New Working Community" button. Empty state copy: "No working communities yet. Sketch your first one to get a starter pack." |
| UX pattern | Pattern 3 Tabbed Detail with document-style content. The community show page is the primary surface; the three artifacts live in three tabs. |
| `db/seeds.rb` | Adds one `AiTemplate` record (`collectivestart_starter_pack_v1`) and one realistic sample `WorkingCommunity` with a saved `FoundingStarterPack` so the demo looks meaningful on first run. |
| Admin nav | No admin changes beyond the boilerplate. The seeded admin user can edit the template at `/admin/ai_templates`. |

---

## 3. Data Model

Two new domain models on top of `User`, `AiTemplate`, and `LlmRequest`.

### WorkingCommunity

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `user_id` | uuid | Foreign key. `belongs_to :user` |
| `name` | string | Required. Length 2 to 80. **(template variable)** |
| `purpose` | text | Required. Length 50 to 1500. **(template variable)** |
| `jurisdiction` | string | Required. Length 2 to 80. Free-form (US state name, country name, or "unsure"). **(template variable)** |
| `founding_team_size` | integer | Required. Range 2 to 50. **(template variable)** |
| `business_model` | text | Required. Length 50 to 1500. **(template variable)** |
| `legal_form_preference` | string | Required. Enum: `worker_coop`, `multi_stakeholder_coop`, `employee_owned_llc`, `benefit_corporation`, `unsure`. **(template variable)** |
| `created_at` / `updated_at` | datetime | |

Associations:
- `belongs_to :user`
- `has_one :founding_starter_pack, dependent: :destroy`

Validations:
- All listed fields required with the listed lengths and ranges.
- `legal_form_preference` must be one of the five enum values.
- A user can have at most 25 working communities. (Soft cap; the form rejects with a clear message. Defends against accidental seed of the LlmRequest log during exploration.)

### FoundingStarterPack

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `working_community_id` | uuid | Foreign key. `belongs_to :working_community` |
| `conversation_summary` | text | Parsed from Gemini output (Artifact 1). |
| `business_model_canvas` | text | Parsed from Gemini output (Artifact 2). |
| `legal_form_comparison` | text | Parsed from Gemini output (Artifact 3). |
| `open_questions` | text | Parsed from Gemini output (the three flagged questions). |
| `gemini_raw` | text | The unparsed Gemini response. **(Gemini output, used for Show raw response toggle)** |
| `generated_at` | datetime | When the starter pack was generated. |
| `created_at` / `updated_at` | datetime | |

Associations:
- `belongs_to :working_community`
- `has_one :user, through: :working_community`

Validations:
- `working_community_id` required and unique (one starter pack per community; regenerating overwrites in place).

Behavior:
- A community can be edited any time.
- Generating a starter pack creates the record if missing or replaces all four parsed fields and the raw field if it already exists.
- The four parsed fields can be empty if parsing fails. The view always shows the raw response toggle so the user is never blocked by parser failure.

### What's Intentionally NOT Here

- No `Member`, `Proposal`, `DecisionRecord`, `BusinessModelCanvas`, `LegalFormRecord`, or `OnboardingPlan`. These are production app concepts; this demo isolates the founding starter pack only.
- No multi-stage workflow, no founder workspace, no OWNERS health assessment.
- No team collaboration. Single-user only.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/working_communities` | `working_communities#index` | List the current user's communities. |
| GET | `/working_communities/new` | `working_communities#new` | New community form. |
| POST | `/working_communities` | `working_communities#create` | Create a community. |
| GET | `/working_communities/:id` | `working_communities#show` | Show a community with its starter pack tabs (or an empty state). |
| GET | `/working_communities/:id/edit` | `working_communities#edit` | Edit form. |
| PATCH | `/working_communities/:id` | `working_communities#update` | Update a community. |
| DELETE | `/working_communities/:id` | `working_communities#destroy` | Delete a community and its starter pack. |
| POST | `/working_communities/:id/founding_starter_pack` | `founding_starter_packs#create` | Generate (or regenerate) the starter pack for a community. Triggers the Gemini call. |

All routes return HTML. The boilerplate's auth, admin, and password routes are unchanged.

---

## 5. Controllers and Actions

### `WorkingCommunitiesController`

Inherits from `ApplicationController` (which already requires authentication). Scopes everything to `current_user`.

- `index`: lists `current_user.working_communities.order(created_at: :desc)`. Renders the dashboard list.
- `new`: instantiates a blank `WorkingCommunity` for the form.
- `create`: builds with `current_user.working_communities.new(community_params)`. On success, redirects to `show`. On failure, re-renders `new` with the standard Bootstrap form errors partial.
- `show`: loads `current_user.working_communities.find(params[:id])`. Eager loads `founding_starter_pack`. Renders the show page with the tabbed starter pack or the empty "Generate your starter pack" state if no pack exists yet.
- `edit` / `update`: standard Rails form. Editing a community does not delete its existing starter pack; the user can regenerate manually.
- `destroy`: deletes the community and its starter pack. Redirects to `index` with a flash.

Strong parameters: `:name`, `:purpose`, `:jurisdiction`, `:founding_team_size`, `:business_model`, `:legal_form_preference`.

### `FoundingStarterPacksController`

Inherits from `ApplicationController`. Single action: `create`.

- `create`:
  1. Loads the community via `current_user.working_communities.find(params[:working_community_id])`.
  2. Calls `GeminiService.generate(template: "collectivestart_starter_pack_v1", variables: variables_for(community))` where `variables_for` returns a hash of the six template variables.
  3. On success: parses the response into the four sections, creates or updates the `FoundingStarterPack`, sets `gemini_raw` to the unparsed response, redirects to the community show page with a success flash.
  4. On `GeminiService::GeminiError` (and its subclasses for gatekeeper, budget, timeout): renders the boilerplate's shared `_ai_error_alert.html.erb` partial inline on the community show page via Turbo Stream, with a "Try again" button that reissues the same `POST`. The error message text comes from the boilerplate's friendly error-class-to-copy mapping; this controller adds no custom error UI.

The parser is a small private method in this controller (or a `FoundingStarterPackParser` class for testability). It splits on the documented delimiter sequence (see Section 7) and assigns each section to its field. If parsing fails, the four parsed fields are set to nil and the raw response is still saved; the view's empty-section placeholders point users at the raw toggle.

---

## 6. Views

### `home/index.html.erb`

Replaces the boilerplate placeholder. Hero with the tagline, one paragraph of explanation, and three preview cards that name the three artifacts (Founding Conversation, Business Model Canvas, Legal Form Comparison) with a one-line description each. Primary CTA is "Sign up" (or "Go to dashboard" for signed-in users).

### `dashboard/show.html.erb`

Replaces the boilerplate placeholder. Renders the user's working communities as a vertical list of Bootstrap cards, each showing name, jurisdiction, founding team size, and a "View" button. A primary "New Working Community" button sits above the list. Empty state: a single illustrated card with copy and a CTA.

### `working_communities/index.html.erb`

Same content as the dashboard list, accessed via the navbar link. (The dashboard and the index view share a `_communities_list.html.erb` partial.)

### `working_communities/new.html.erb` and `edit.html.erb`

A single-column Bootstrap form rendered via a shared `_form.html.erb` partial. Fields:

- Name (`text_field`)
- Purpose (`text_area`, 5 rows, with character count via Stimulus `character-counter` controller)
- Jurisdiction (`text_field` with a small helper text: "US state name, country name, or 'unsure' if undecided")
- Founding team size (`number_field`, min 2 max 50)
- Business model (`text_area`, 5 rows, with character count)
- Legal form preference (`select` with the five enum options as friendly labels)

Submit button uses `var(--accent)`. Cancel link returns to the dashboard.

### `working_communities/show.html.erb`

Primary surface. Layout:

1. Top-of-page persistent yellow alert (`alert alert-warning`) reading: "Every artifact below is a working draft for lawyer review, never a filing-ready document. CollectiveStart helps you think; it does not give legal advice."
2. Header section: the community name as `h1`, a subtitle line with jurisdiction, founding team size, and legal form preference rendered as Bootstrap badges. Action toolbar on the right: "Edit" (`btn-outline-secondary`), "Delete" (`btn-outline-danger`, with confirmation), "Generate Starter Pack" (`btn-primary`) or "Regenerate Starter Pack" if a pack already exists.
3. Empty state (no pack yet): a single centered card explaining what the starter pack will contain and a primary CTA that submits the generate form.
4. Pack present state: Bootstrap `nav-tabs` with three tabs:
   - "Founding Conversation" (default active)
   - "Business Model Canvas"
   - "Legal Form Comparison"
5. Below the tabs, an "Open Questions" callout in an `alert alert-info` rendering the three open questions the AI flagged.
6. Below that, a "Show raw response" Bootstrap collapse that reveals the unparsed `gemini_raw` field. This is required by the boilerplate's UX expectation.
7. Footer line: "Generated [timestamp]. AI-generated content can be incorrect; verify before acting."

Tabs are rendered as Turbo Frames keyed by tab so the active tab is reflected in the URL via a `?tab=` query parameter and is bookmarkable. Each tab's body renders the corresponding text field through Rails' `simple_format` helper (the AI returns markdown-flavored text; the boilerplate already includes the `redcarpet` gem for the admin template editor's preview, so the show page reuses a `markdown` helper that wraps Redcarpet for safe HTML rendering of the AI output).

### `working_communities/_form.html.erb`

Shared form partial used by `new` and `edit`.

### `_communities_list.html.erb`

Shared partial rendering the card list, used by the dashboard and the index page.

### Turbo and Stimulus

- The Generate button submits a Turbo form. The response is a Turbo Stream that replaces the empty state (or the existing pack section) with the new pack content. On error, the response is a Turbo Stream that prepends the inline error alert and a "Try again" button.
- The character counter on text areas is a Stimulus `character-counter` controller (a small per-app addition; nothing in the boilerplate counts characters).
- The tab nav uses Bootstrap's standard tab JS plus a tiny Stimulus `tab-url-sync` controller that updates the URL's `?tab=` parameter on tab change so deep links work.

---

## 7. AI Templates and Gemini Integration

This demo seeds one template. All Gemini interaction goes through `GeminiService.generate(template: "collectivestart_starter_pack_v1", variables: {...})`.

### Template `collectivestart_starter_pack_v1`

**Description:** Generates a Founding Starter Pack for a working community: founding conversation summary, cooperative business model canvas, and a legal form comparison. Every artifact must carry a DRAFT FOR LAWYER REVIEW banner.

**Model:** `gemini-2.0-flash`. Default. The output is structured prose at moderate length; flash is sufficient and the cheapest current option.

**Max output tokens:** 3500. Higher than the 2000 default. The starter pack is comprehensive across three artifacts plus open questions; 2000 tokens truncates the third artifact in practice.

**Temperature:** 0.4. Lower than the 0.7 default. The output is structurally rigid (mandatory banner, mandatory section delimiters, mandatory canvas sub-sections, mandatory comparison rows). Lower temperature reduces formatting drift and missed sections.

**System prompt (full text):**

```
You are a co-op formation assistant inside CollectiveStart, an operating system
for forming and running worker cooperatives and other shared-ownership firms.
You produce a Founding Starter Pack: a structured first draft a founding team
can react to before talking to a co-op attorney.

You are not a lawyer. You do not give legal advice. Every artifact you produce
is a working draft, never a filing-ready document.

You must produce output in this exact structure, with these exact delimiters,
in this exact order:

=== ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===
> DRAFT FOR LAWYER REVIEW. This is a synthesis to react to, not a record of
> a conversation. Verify every claim with your team and a qualified co-op
> attorney before acting on it.

[Five short subsections, each a labelled paragraph, each grounded in the
team's described purpose, business model, jurisdiction, team size, and stated
legal form preference:
- Likely shared values
- Business model thinking the team will need to align on
- Capital plan considerations specific to a member-owned firm
- Governance preferences this team profile suggests
- Member commitments that would match those values and that governance]

=== ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===
> DRAFT FOR LAWYER REVIEW. This canvas is a starting point for a founding
> conversation, not a finished business plan. Validate every assumption
> with your team and prospective members.

[Nine subsections, each labelled, each two to four sentences:
- Customer Segments
- Value Proposition
- Channels
- Member Relationships (replaces "Customer Relationships"; describe how
  member-owners relate to each other and to the firm, not how the firm
  relates to customers)
- Revenue Streams
- Key Activities
- Key Resources
- Ownership Structure (replaces "Key Partnerships"; describe who owns the
  firm, how ownership is acquired, and how it transfers)
- Cost and Capital Structure]

=== ARTIFACT 3: LEGAL FORM COMPARISON ===
> DRAFT FOR LAWYER REVIEW. Legal form selection is jurisdiction-specific
> and depends on facts not in this prompt. Do not file anything based on
> this comparison. Use it to prepare questions for a qualified co-op
> attorney in your jurisdiction.

[A trade-off comparison of the three legal forms most plausible for this
team given the stated jurisdiction, business model, and founding team
size. For each form, produce a labelled block with these six rows in
this order:
- Governance structure
- Capital implications
- Tax treatment
- Member liability
- Exit mechanics
- One signature risk

If the user's stated legal_form_preference is one of "worker_coop",
"multi_stakeholder_coop", "employee_owned_llc", or "benefit_corporation",
include that form as the first of the three. If it is "unsure", choose
the three most plausible based on the rest of the inputs and explain in
one sentence at the top of this artifact why those three were chosen.]

=== OPEN QUESTIONS ===
> Three questions this team should answer before going further. Number them.

[Three numbered questions, each one sentence, each grounded in a specific
gap or tension in the team's described inputs. Avoid generic startup
questions; make them specific to the inputs you were given.]

Hard rules:
- The "DRAFT FOR LAWYER REVIEW" banner is mandatory at the top of each of
  the three artifacts. If you cannot produce the banner, do not produce
  the artifact.
- The four delimiters (=== ARTIFACT 1: ... ===, === ARTIFACT 2: ... ===,
  === ARTIFACT 3: ... ===, === OPEN QUESTIONS ===) must appear exactly
  as written, on their own line, in this order. Do not add or remove
  delimiters.
- Do not address the user as "you". Address the founding team in the
  third person ("the team", "members", "founders").
- Do not name specific attorneys, firms, or filing services.
- Do not cite case law or statute numbers; you do not have a verifiable
  source.
- If the inputs are too thin to produce a grounded artifact (for
  example, a one-sentence purpose), still produce all three artifacts
  but lead each with a one-sentence note that the inputs were thin and
  the team should expand the inputs and regenerate.
- Use plain language. Define any term a non-lawyer founder would not
  recognize the first time it appears.
- Output is markdown. Use headings (##), bold (**), and bullet lists
  where they aid scanning. Do not use tables; the host app renders
  the markdown and tables render inconsistently.
```

**User prompt template (full text):**

```
Working community details:

Proposed name: {{community_name}}
Jurisdiction: {{jurisdiction}}
Founding team size: {{founding_team_size}}
Stated legal form preference: {{legal_form_preference}}

Purpose:
{{purpose}}

Intended business model:
{{business_model}}

Produce the Founding Starter Pack now, following the exact structure and
delimiters specified in the system instructions.
```

**Variables consumed:**

- `{{community_name}}` from `WorkingCommunity#name`
- `{{jurisdiction}}` from `WorkingCommunity#jurisdiction`
- `{{founding_team_size}}` from `WorkingCommunity#founding_team_size`
- `{{legal_form_preference}}` from `WorkingCommunity#legal_form_preference` (rendered as the friendly label, e.g., "worker cooperative" rather than the enum string)
- `{{purpose}}` from `WorkingCommunity#purpose`
- `{{business_model}}` from `WorkingCommunity#business_model`

**Where it's called:** `FoundingStarterPacksController#create`.

**Expected output format:** Markdown with the four delimiter lines exactly as specified. The controller's parser splits on `=== ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===`, `=== ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===`, `=== ARTIFACT 3: LEGAL FORM COMPARISON ===`, and `=== OPEN QUESTIONS ===`, then assigns each section's body to `conversation_summary`, `business_model_canvas`, `legal_form_comparison`, and `open_questions` respectively.

**How the response is parsed and rendered:**

1. The raw response is stored in `gemini_raw` first, before any parsing, so the raw toggle always works.
2. The parser is forgiving: it accepts whitespace and case variation around the delimiters, but the literal "ARTIFACT 1", "ARTIFACT 2", "ARTIFACT 3", and "OPEN QUESTIONS" anchors must be present.
3. Each parsed section is stored as a markdown string and rendered through the boilerplate's `markdown` helper (Redcarpet) on the show page.
4. If a section is missing after parsing, its tab shows a small alert: "This section did not parse cleanly. Open the raw response below to see it, or regenerate."

**Domain field that stores the raw response:** `FoundingStarterPack#gemini_raw`.

**Author's notes (`AiTemplate#notes`):**

```
This template enforces the three-artifact contract structurally through
delimiter requirements rather than schema constraints. The DRAFT FOR
LAWYER REVIEW banner is mandatory and is the single most important
safety feature of this app; do not remove it during prompt iteration.

Known failure modes to watch for:
- Gemini occasionally drops the fourth delimiter (=== OPEN QUESTIONS ===)
  and writes the questions inline at the end of artifact 3. The parser
  surfaces this as a missing open_questions field with a non-empty
  legal_form_comparison containing question marks.
- For "unsure" legal form preferences, Gemini sometimes picks the same
  three forms regardless of inputs. If iterating, add specific guidance
  to the system prompt about how jurisdiction and business model should
  influence the choice.
- Temperature above 0.6 produces creative section headings that break
  the parser. Stay at or below 0.4 unless the parser is also relaxed.

When iterating in the admin template editor, test with at least three
sample variable sets:
1. A small worker co-op (4 founders, US state, services business)
2. A multi-stakeholder co-op (12 founders, country, food retail)
3. An "unsure" team (6 founders, no jurisdiction, software services)
```

This demo does not use Gemini's function calling. It is a single-shot prompt; no agent loop, no tool calls.

---

## 8. AI Safety Considerations (Specific to This App)

Forming a legal entity is a regulated, jurisdiction-specific activity with consequential outputs. This demo treats that seriously.

**Content sensitivity.** The output advises a founding team on legal form, governance, capital structure, tax treatment, member liability, and exit mechanics. None of this is legal advice, and the AI is not qualified to give it. The risk is not embarrassment; it is a team filing a benefit corporation in a state where their needs would have been better served by an LLC, or skipping a co-op-specific provision in their bylaws because the AI did not know to mention it.

**Consequential outputs.** The worst case is a team that treats the starter pack as a finished plan, raises money against it, and discovers six months later that the legal form is wrong for their jurisdiction. The mitigations operate at three levels:

1. **Template-level structural enforcement.** The system prompt requires every one of the three artifacts to begin with a "DRAFT FOR LAWYER REVIEW" banner. The prompt is structured so that the AI cannot produce a compliant output without the banner. The author of the demo can see this is enforced by reviewing the system prompt in `/admin/ai_templates/collectivestart_starter_pack_v1/edit` and by inspecting the test panel output before saving.
2. **UI-level persistent reminder.** The community show page renders a yellow alert at the top of every view of the starter pack: "Every artifact below is a working draft for lawyer review, never a filing-ready document. CollectiveStart helps you think; it does not give legal advice."
3. **Output-level prohibitions in the system prompt.** The AI is instructed not to cite case law, statute numbers, specific attorneys, or filing services. It is instructed to define any term a non-lawyer founder would not recognize. It is instructed to address the team in the third person to discourage the parasocial framing that produces over-trust.

**Domain accuracy requirements.** Co-op law varies materially by US state and by country. A worker cooperative statute exists in Massachusetts and California (among others) but not in every US state; the AI does not have a verifiable source for which states have what statutes. The system prompt prohibits citing specific statutes precisely because the AI cannot back up the citation. The legal form comparison is framed as questions to bring to a co-op attorney, not answers.

**App-specific disclaimers.** Beyond the boilerplate's footer note ("AI-generated content can be incorrect. Verify before acting."), this app adds:

- The persistent yellow alert at the top of the show page (described above).
- A per-artifact "DRAFT FOR LAWYER REVIEW" banner inside the AI output itself (enforced by the template).
- A footer line on the show page noting the generation timestamp and a verify-before-acting reminder.

**Tightened settings.** The default `max_output_tokens` is raised from 2000 to 3500 to fit the comprehensive output. The default `temperature` is lowered from 0.7 to 0.4 to reduce formatting drift. The boilerplate's per-user daily call cap (default 50) is unchanged; for a single-user local demo, 50 calls per day is generous and there is no business reason to tighten it.

**What this demo deliberately does NOT do (for safety reasons):**

- It does not generate filing-ready documents (operating agreements, bylaws, articles of incorporation). The production app has those tools; the demo is scoped to the founding conversation only, where the AI's strengths outweigh its weaknesses.
- It does not store member personal information. The form asks only for the founding team size, not names or roles.
- It does not estimate filing fees, taxes owed, or capital required. Numbers from the AI in those domains are confabulation.
- It does not refer the user to specific attorneys or filing services. Recommending a specific attorney is a regulated activity in many jurisdictions and outside the scope of an AI demo.
- It does not log the user's purpose or business model text outside the standard `LlmRequest` log. The boilerplate's request log stores token counts, not prompt text.

---

## 9. RSpec Outline

New spec files for this demo. Boilerplate specs (`user_spec.rb`, `ai_template_spec.rb`, `llm_request_spec.rb`, `gemini_service_spec.rb`, `ai_gatekeeper_spec.rb`, `ai_budget_checker_spec.rb`, the auth request specs, and the admin specs) are inherited and not redescribed.

### `spec/models/working_community_spec.rb`

- Validates presence and length of `name`, `purpose`, `jurisdiction`, `business_model`.
- Validates `founding_team_size` is between 2 and 50.
- Validates `legal_form_preference` is one of the five enum values.
- Enforces the 25-community-per-user soft cap with a clear validation error.
- `belongs_to :user` and `has_one :founding_starter_pack` associations behave correctly.

### `spec/models/founding_starter_pack_spec.rb`

- Validates presence and uniqueness of `working_community_id`.
- Reads the user via `working_community.user` (delegation tested).
- Allows all four parsed fields to be nil while `gemini_raw` is present.
- `dependent: :destroy` on the parent community removes the pack.

### `spec/services/founding_starter_pack_parser_spec.rb`

- Splits a well-formed response into four sections cleanly.
- Tolerates whitespace and case variation around delimiters.
- Returns nil sections when delimiters are missing, while preserving the raw text.
- Handles the known failure mode where `=== OPEN QUESTIONS ===` is dropped (returns the legal form comparison plus a nil open_questions, does not raise).

### `spec/requests/working_communities_spec.rb`

- A signed-in user can create, view, edit, and delete their own community.
- `index` only returns the current user's communities.
- A signed-in user cannot access another user's community via `show`, `edit`, `update`, or `destroy` (all return 404).
- Form validation errors render the `new` template with Bootstrap error classes.

### `spec/requests/founding_starter_packs_spec.rb`

- The `create` action calls `GeminiService.generate` with the correct template name and variable hash. (Uses the boilerplate's `gemini_test_double`.)
- A successful Gemini response creates a `FoundingStarterPack` with all four parsed fields and the raw response.
- Regenerating overwrites in place rather than creating a second pack.
- An `LlmRequest` record is created on every Gemini call (success and failure).
- A `GeminiService::GatekeeperError` renders the inline error alert with a retry button and does not create a starter pack.
- A `GeminiService::BudgetExceededError` renders the budget-exceeded variant of the error alert.
- A `GeminiService::TimeoutError` renders the timeout variant.
- A signed-in user cannot generate a starter pack for another user's community.

### `spec/system/community_show_tabs_spec.rb` (one targeted system spec)

System specs are not the boilerplate default, but the tabbed show page benefits from one end-to-end check.

- Loads the show page with a seeded pack and verifies all three tabs render their content.
- Clicks each tab and verifies the URL updates with the correct `?tab=` parameter.
- Toggles the "Show raw response" collapse and verifies the raw text appears.
- Verifies the persistent yellow lawyer-review alert is on every tab.

---

## 10. Seed Data

Two parts on top of the boilerplate's seeded admin user.

### AiTemplate seeds

`db/seeds.rb` creates one record:

```
AiTemplate.find_or_create_by!(name: "collectivestart_starter_pack_v1") do |t|
  t.description       = "Founding Starter Pack for a working community: " \
                        "founding conversation, business model canvas, " \
                        "legal form comparison, plus three open questions."
  t.system_prompt     = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_system.txt"))
  t.user_prompt_template = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_user.txt"))
  t.model             = "gemini-2.0-flash"
  t.max_output_tokens = 3500
  t.temperature       = 0.4
  t.notes             = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_notes.txt"))
end
```

The three prompt text files live under `db/seed_prompts/` so the prompt content is version-controlled in plain text and easy to edit. The file contents match Section 7 exactly.

### Domain seeds

`db/seeds.rb` also creates one realistic sample working community for the demo user, with a saved starter pack so the show page looks meaningful on first run:

```
demo_user = User.find_by!(email: "demo@example.com")

community = demo_user.working_communities.find_or_create_by!(name: "North Tower Software Cooperative") do |c|
  c.purpose = "A worker cooperative that builds and maintains custom internal tools for " \
              "mission-driven nonprofits in the Northeast US. We want stable, fairly-paid " \
              "engineering work and member-owners who set their own rates and choose their " \
              "own clients."
  c.jurisdiction = "Massachusetts"
  c.founding_team_size = 5
  c.business_model = "Project-based custom software development for nonprofits, billed at a " \
                     "blended hourly rate. Each project staffs two to three members. Members " \
                     "share overhead and split distributable surplus by hours worked."
  c.legal_form_preference = "worker_coop"
end

community.create_founding_starter_pack!(
  conversation_summary: File.read(Rails.root.join("db/seed_starter_pack/conversation_summary.md")),
  business_model_canvas: File.read(Rails.root.join("db/seed_starter_pack/business_model_canvas.md")),
  legal_form_comparison: File.read(Rails.root.join("db/seed_starter_pack/legal_form_comparison.md")),
  open_questions: File.read(Rails.root.join("db/seed_starter_pack/open_questions.md")),
  gemini_raw: File.read(Rails.root.join("db/seed_starter_pack/gemini_raw.md")),
  generated_at: Time.current
) unless community.founding_starter_pack
```

The `db/seed_starter_pack/` files contain a hand-curated example output (no API calls during seeding) so the demo runs without a Gemini API key for the show page tour. The user only needs the API key when they generate a new pack.

---

## 11. README Additions

App-specific sections that override or extend the boilerplate's README template.

### Top of README

```
# CollectiveStart Demo

> Tell me about your working community. Get your founding starter pack.

CollectiveStart Demo is an open source Rails 8 demo of one feature from
CollectiveStart, the operating system for forming and running working
communities. Sketch a worker cooperative or other shared-ownership firm in
one form; get a draft starter pack with three artifacts: a founding
conversation summary, a cooperative business model canvas, and a legal
form comparison.

Every artifact is a working draft for lawyer review, never a filing-ready
document.
```

### Screenshot

A note at the top of the README:

```
[Screenshot of the community show page with the three tabs and the yellow
lawyer-review alert. Replace this line with the screenshot once recorded.]
```

### Why I built this

```
I'm building CollectiveStart, the multi-tenant SaaS suite for forming and
running working communities. The full app handles member onboarding,
governance, decision records, OWNERS health assessments, and operating
documents. This demo isolates the founding engine: the moment a team
sits down with a half-formed idea and wants something to react to.

I open sourced it because the founding conversation is where the
loneliness of co-op formation hurts most, and a working draft to react
to is more useful than another blog post. If you fork this and adapt the
prompt for your jurisdiction or your kind of working community, send me
the diff. I'd love to see it.

The production app lives at https://collectivestart.example. This demo
is MIT licensed; do whatever you want with it.
```

### Tunable AI prompt

```
The Gemini prompt that generates the Founding Starter Pack is editable
without redeploying. Sign in as the seeded admin user
(demo@example.com / password123), navigate to /admin/ai_templates,
and open the collectivestart_starter_pack_v1 record. The editor has a
live test panel: type sample variable values, click Test, see Gemini's
response inline, save when you're happy.

If you change the prompt and want your changes preserved across
db:seed runs, copy the updated text back into
db/seed_prompts/collectivestart_starter_pack_v1_system.txt.
```

### App-specific setup

No additional setup beyond `bin/setup`. The demo runs with only a Gemini API key.

The README's standard "Stack", "Setup", "License", "AI Safety Posture", and "About the Author" sections come from the boilerplate template and are not rewritten here.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

This app uses Bootstrap 5 in dark mode (set in the boilerplate via `data-bs-theme="dark"` on the html element).

### Component choices

- **Form-heavy creation, document-style detail.** Pattern 6 Wizard would have been overkill for six fields; the new and edit pages use a single-column Bootstrap form. The detail page uses Pattern 3 Tabbed Detail.
- **Cards** for the dashboard list of communities. One card per community with name, jurisdiction, team size, and a primary "View" button.
- **`nav-tabs`** (the underlined variant, not pills) for the three artifact tabs on the show page. Underlined tabs read better as a "document with sections" treatment; pills read more as switchable views.
- **Alerts** for the persistent lawyer-review reminder (warning) and the open questions callout (info).
- **Badges** for jurisdiction, founding team size, and legal form preference in the show page subtitle.
- **Bootstrap collapse** for the "Show raw response" toggle, per the boilerplate's UX expectation.
- **Bootstrap modal** is not used. The form is on its own page; the AI generation is a button submit, not a modal.

### Accent color application

`--accent: #0f766e` and `--accent-hover: #0d5e58` are set in `_accent.scss`. They are applied to:

- All `.btn-primary` buttons (Generate, Save, Sign up, Go to dashboard) via the boilerplate's accent-aware button override.
- The active tab indicator on the `nav-tabs` strip (custom override of Bootstrap's default `--bs-nav-tabs-link-active-color`).
- All in-text links on the show page and home page.
- Form focus rings on the new and edit forms.
- Navbar brand text.
- Empty state CTAs.

Status badges (success, warning, danger, info) use Bootstrap's semantic colors, not the accent. The yellow `alert alert-warning` for the lawyer-review reminder uses Bootstrap's warning palette so it reads as a caution, not a brand element.

### Custom CSS

Beyond the accent override, this app adds a small `_community_show.scss` partial with:

- `.starter-pack-tab-content` rule that gives each tab body a max readable width (around 720px) and consistent vertical rhythm, since the AI output is markdown prose.
- `.lawyer-review-banner` rule that pins the yellow alert to the top of the show page with a subtle border accent in `var(--accent)` to tie it visually to the brand without softening its caution affordance.
- `.character-counter` rule for the small grey counter under the textarea, used by the Stimulus controller.

Total custom CSS is well under 50 lines. Everything else uses Bootstrap utilities.

### Mobile behavior

- Dashboard card list collapses to single column on `sm` and below.
- The new and edit forms are already single-column.
- The show page header's action toolbar collapses into a dropdown kebab menu on `sm`.
- The three artifact tabs become a horizontally scrollable strip with snap points (Bootstrap's default behavior plus a one-line overflow utility), per the Pattern 3 mobile guidance.
- The yellow lawyer-review alert remains visible above the tabs on every breakpoint. It is the most important UI element of the show page and never collapses or hides.

---

*v1.0 - CollectiveStart Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
