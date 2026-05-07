# Phase 4 — AI Template & Parser

**Goal:** Seed prompt files exist on disk. The `FoundingStarterPackParser` service correctly parses Gemini's structured output. The `collectivestart_starter_pack_v1` AiTemplate is seeded in the database.

**Depends on:** Phase 2 complete (models exist). Boilerplate's `AiTemplate` model and `db/seeds.rb` base exist.

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §7, §10

**Reference docs to read first:**
- `docs/ai-templates.md` — AiTemplate structure, seeding pattern, variable syntax
- `docs/ai-guardrails.md` — GeminiService flow (for understanding how the template is consumed)

---

## Context

The template uses `{{variable_name}}` syntax. Six variables map directly from `WorkingCommunity` fields. The model `gemini-2.5-flash` is used instead of `gemini-2.0-flash` (which is deprecated for new API keys). The seed files are plain text so they can be version-controlled and edited without touching Ruby code.

---

## 1. Create `db/seed_prompts/` Directory and Files

Create three files. Contents are reproduced in full below.

### `db/seed_prompts/collectivestart_starter_pack_v1_system.txt`

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

### `db/seed_prompts/collectivestart_starter_pack_v1_user.txt`

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

### `db/seed_prompts/collectivestart_starter_pack_v1_notes.txt`

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

---

## 2. Update `db/seeds.rb`

Add the AiTemplate seed block to `db/seeds.rb`. Use `find_or_create_by!` so re-seeding is idempotent. Add this after the boilerplate's existing seed blocks (health_ping template, demo user):

```ruby
AiTemplate.find_or_create_by!(name: "collectivestart_starter_pack_v1") do |t|
  t.description          = "Founding Starter Pack for a working community: " \
                           "founding conversation, business model canvas, " \
                           "legal form comparison, plus three open questions."
  t.system_prompt        = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_system.txt"))
  t.user_prompt_template = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_user.txt"))
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 3500
  t.temperature          = 0.4
  t.notes                = File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_notes.txt"))
end
```

> **Model note:** The spec lists `gemini-2.0-flash`, but that model returns 404 for new API keys. Use `gemini-2.5-flash` instead.

---

## 3. `FoundingStarterPackParser` Service

`app/services/founding_starter_pack_parser.rb`:

The parser splits on the four delimiter anchors using a forgiving regex (tolerates whitespace and case variation around the `===` markers, but requires the literal anchor strings). Returns a plain struct so tests can verify each field independently.

```ruby
class FoundingStarterPackParser
  Result = Struct.new(:conversation_summary, :business_model_canvas,
                      :legal_form_comparison, :open_questions, keyword_init: true)

  DELIMITER_PATTERN = /
    ===\s*
    (?:
      (ARTIFACT\s+1[^=]*)   |   # group 1: artifact 1
      (ARTIFACT\s+2[^=]*)   |   # group 2: artifact 2
      (ARTIFACT\s+3[^=]*)   |   # group 3: artifact 3
      (OPEN\s+QUESTIONS[^=]*)    # group 4: open questions
    )
    \s*===
  /ix

  def self.parse(raw_text)
    new(raw_text).parse
  end

  def initialize(raw_text)
    @raw = raw_text.to_s
  end

  def parse
    sections = split_sections
    Result.new(
      conversation_summary:  sections[:artifact1],
      business_model_canvas: sections[:artifact2],
      legal_form_comparison: sections[:artifact3],
      open_questions:        sections[:open_questions]
    )
  end

  private

  def split_sections
    # Split on any delimiter, capture which type it is
    parts      = @raw.split(DELIMITER_PATTERN).map(&:strip)
    sections   = { artifact1: nil, artifact2: nil, artifact3: nil, open_questions: nil }
    current    = nil

    # parts[0] is content before first delimiter (preamble, ignored)
    # subsequent pairs: [delimiter_match_groups..., content_body]
    # The split with a capturing group returns alternating: content, group1, group2... content...
    # Easier to scan for anchor positions in the original string
    scan_sections(sections)
  end

  def scan_sections(sections)
    anchors = {
      artifact1:      /===\s*ARTIFACT\s+1[^=]*===/i,
      artifact2:      /===\s*ARTIFACT\s+2[^=]*===/i,
      artifact3:      /===\s*ARTIFACT\s+3[^=]*===/i,
      open_questions: /===\s*OPEN\s+QUESTIONS[^=]*===/i
    }

    positions = anchors.transform_values do |pattern|
      match = @raw.match(pattern)
      match ? match.end(0) : nil
    end

    ordered_keys = %i[artifact1 artifact2 artifact3 open_questions]
    ordered_keys.each_with_index do |key, idx|
      start_pos = positions[key]
      next if start_pos.nil?

      # End at the next present anchor, or end of string
      next_key = ordered_keys[(idx + 1)..].find { |k| positions[k] }
      end_pos = next_key ? (@raw.index(anchors[next_key]) || @raw.length) : @raw.length

      sections[key] = @raw[start_pos...end_pos].strip
    end

    sections
  end
end
```

---

## RSpec Tests — Phase 4

**`spec/services/founding_starter_pack_parser_spec.rb`**

Build a well-formed fixture string at the top of the spec:

```ruby
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
```

Cover all of the following:

**Well-formed input:**
- All four fields are non-nil and non-empty
- `conversation_summary` includes "DRAFT FOR LAWYER REVIEW"
- `open_questions` includes the three numbered questions
- No field includes another artifact's delimiter

**Whitespace tolerance:**
- Extra spaces around `===` markers parse correctly
- Leading/trailing whitespace is stripped from each section

**Case tolerance:**
- Lowercase `=== artifact 1: founding conversation summary ===` parses correctly

**Missing `=== OPEN QUESTIONS ===`:**
- `open_questions` is nil
- Other three sections are non-nil and correctly populated
- Does not raise

**All delimiters missing:**
- All four fields are nil
- Does not raise

**Empty string input:**
- All four fields are nil
- Does not raise

**Nil input:**
- All four fields are nil
- Does not raise

---

## Manual Checks — Phase 4

- [ ] `rails db:seed` completes without errors
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Visit `/admin/ai_templates` → `collectivestart_starter_pack_v1` is listed
- [ ] Click Edit → verify:
  - Model is `gemini-2.5-flash`
  - Max output tokens is `3500`
  - Temperature is `0.4`
  - System prompt begins with "You are a co-op formation assistant..."
  - User prompt template contains `{{community_name}}`, `{{jurisdiction}}`, `{{founding_team_size}}`, `{{legal_form_preference}}`, `{{purpose}}`, `{{business_model}}`
- [ ] The test panel in the admin editor auto-detects and renders input fields for all six variables
- [ ] `rails db:seed` a second time → idempotent (no duplicate AiTemplate records, no errors)
