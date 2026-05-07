# CollectiveStart Demo — Build Tasks

**Source spec:** `docs/open-collectivestart/collectivestart-demo-spec.md`
**Boilerplate docs:** `docs/ai-guardrails.md`, `docs/ai-templates.md`, `docs/testing.md`, `docs/turbo-stimulus-patterns.md`

Each phase is a self-contained document. Pull one phase into context and work through it completely before starting the next. Each phase file includes implementation tasks, RSpec tests (where applicable), and manual checks.

Status key: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Phase 1 — App Configuration & Branding
**Spec:** [phase_1_branding.md](phase_1_branding.md)

- [x] `.env.example` updated with CollectiveStart values
- [x] Accent color `#0f766e` set in `application.css`
- [x] "My Communities" nav link added to layout
- [x] `home/index.html.erb` replaced with CollectiveStart landing page
- [x] Manual checks passed (server running, branding visible)

---

## Phase 2 — Data Models & Migrations
**Spec:** [phase_2_data_models.md](phase_2_data_models.md)

- [x] `working_communities` migration created and run
- [x] `founding_starter_packs` migration created and run
- [x] `WorkingCommunity` model with validations and 25-community cap
- [x] `FoundingStarterPack` model with uniqueness constraint
- [x] `User` model updated with `has_many :working_communities`
- [x] Factories for both models (including `:with_pack` trait)
- [x] `spec/models/working_community_spec.rb` — all examples pass
- [x] `spec/models/founding_starter_pack_spec.rb` — all examples pass
- [x] Manual console checks passed

---

## Phase 3 — WorkingCommunity CRUD
**Spec:** [phase_3_crud.md](phase_3_crud.md)

- [x] Routes added (`resources :working_communities` with nested `founding_starter_pack`)
- [x] `WorkingCommunitiesController` — all 7 actions, scoped to `current_user`
- [x] `_communities_list.html.erb` shared partial
- [x] `working_communities/index.html.erb`
- [x] `dashboard/show.html.erb` replaced
- [x] `working_communities/_form.html.erb` — all 6 fields
- [x] `new.html.erb` and `edit.html.erb`
- [x] `show.html.erb` — empty-state with `id="starter-pack-section"`
- [x] Stimulus `character-counter` controller
- [x] `.character-counter` and `.lawyer-review-banner` CSS rules
- [x] `spec/requests/working_communities_spec.rb` — all examples pass
- [x] Manual browser checks passed

---

## Phase 4 — AI Template & Parser
**Spec:** [phase_4_ai_template.md](phase_4_ai_template.md)

- [x] `db/seed_prompts/` directory created with 3 files (system, user, notes)
- [x] `db/seeds.rb` updated with `collectivestart_starter_pack_v1` AiTemplate
- [x] `FoundingStarterPackParser` service created
- [x] `spec/services/founding_starter_pack_parser_spec.rb` — all examples pass
- [x] Manual admin panel checks passed (template visible, 6 variable inputs detected)

---

## Phase 5 — Founding Starter Pack Generation
**Spec:** [phase_5_generation.md](phase_5_generation.md)

- [x] `FoundingStarterPacksController` — `create` action with Turbo Stream response
- [x] `markdown` helper added to `ApplicationHelper`
- [x] `show.html.erb` updated for pack-present state (tabs, open questions, raw toggle)
- [x] `_starter_pack.html.erb` partial
- [x] `_empty_pack_state.html.erb` partial
- [x] `_generation_error.html.erb` partial
- [x] Stimulus `tab-url-sync` controller
- [x] `.starter-pack-tab-content` CSS rules
- [x] `spec/requests/founding_starter_packs_spec.rb` — all examples pass
- [x] Manual browser checks passed (generation flow, tab sync, error state)

---

## Phase 6 — Seed Data & Final Polish
**Spec:** [phase_6_seed_polish.md](phase_6_seed_polish.md)

- [x] `db/seed_starter_pack/` directory created with 5 files
- [x] `db/seeds.rb` updated with "North Tower Software Cooperative" domain seed
- [x] `README.md` updated (title, tagline, why I built this, tunable prompt section)
- [x] `rails db:seed` idempotent on repeat runs
- [x] Manual checks passed (demo user sees seeded community + full pack on first run)

---

## Post-Phase-6 UX Fixes (outside original spec)

- [x] `pack_generator_controller.js` — Stimulus controller: loading spinner + cancel button during generation; listens to `turbo:submit-start`/`turbo:submit-end` on container element
- [x] `show.html.erb` updated — loading card outside `#starter-pack-section` (survives Turbo Stream updates); `data-controller="pack-generator"` on outer div
- [x] `AI_GLOBAL_TIMEOUT_SECONDS` raised to 45 in `.env.example` (default 15s too short for 4-artifact prompt)
- [x] Parse validation added to `FoundingStarterPacksController` — raises `GeminiError` if any artifact is nil, rendering error UI instead of empty tabs
- [x] System prompt updated — added COMPLETION REQUIREMENT rule to prevent Gemini from stopping after Artifact 1
- [x] `max_output_tokens` raised to 8192 in seeds (was 3500; live template updated via admin panel)

---

## Phase 7 — Full Test Suite, QA & Pre-Publish Security
**Spec:** [phase_7_qa_publish.md](phase_7_qa_publish.md)

- [x] `spec/system/community_show_tabs_spec.rb` written and passing
- [x] `bundle exec rspec` — zero failures (168 examples)
- [x] Zero real Gemini API calls in test run
- [x] RuboCop — skipped (not needed for this project)
- [ ] Golden path QA complete
- [ ] Edge case QA complete
- [x] Pre-publish security check complete — no secrets committed; rotate Gemini API key before publishing
- [ ] Repo ready to push to GitHub

---

## Spec Cross-Reference

| Spec Section | Phase | Phase File |
|---|---|---|
| §2 Customizations | 1 | phase_1_branding.md |
| §3 Data Model | 2 | phase_2_data_models.md |
| §4 Routes | 3 | phase_3_crud.md |
| §5 Controllers | 3, 5 | phase_3_crud.md, phase_5_generation.md |
| §6 Views | 3, 5 | phase_3_crud.md, phase_5_generation.md |
| §7 AI Templates | 4 | phase_4_ai_template.md |
| §8 AI Safety | 5, 7 | phase_5_generation.md, phase_7_qa_publish.md |
| §9 RSpec | 2–5, 7 | Phase files + phase_7_qa_publish.md |
| §10 Seeds | 4, 6 | phase_4_ai_template.md, phase_6_seed_polish.md |
| §11 README | 6 | phase_6_seed_polish.md |
| §12 Bootstrap/CSS | 1, 5 | phase_1_branding.md, phase_5_generation.md |

---

## Known Spec Deviations

| Item | Spec says | What was built | Reason |
|---|---|---|---|
| AI model | `gemini-2.0-flash` | `gemini-2.5-flash` | `docs/ai-templates.md` documents 2.0-flash as deprecated for new API keys |
| Accent CSS location | `_accent.scss` | `application.css` CSS variable | Propshaft; no SCSS compilation in this stack |
| Turbo response on pack generation | "redirect to show" in §5 prose | Turbo Stream to `#starter-pack-section` | Spec §6 views are authoritative on UX; Turbo Stream avoids full reload |
| Button colors | Bootstrap default blue | Overridden via `--bs-btn-bg` etc. on `.btn-primary` | Bootstrap 5 CDN compiles button colors at build time; CSS variables on `:root` alone are insufficient |
| `max_output_tokens` | 3500 (Phase 4 spec) | 8192 | 3500 produced truncated 4-artifact responses in live testing |
| Loading state during generation | Not in spec | `pack_generator_controller.js` + spinner card | Live testing showed ~18s wait with no feedback; added for usability |
| Generation timeout | 15s default | 45s (`.env.example`) | 15s insufficient for complex 4-artifact prompt; confirmed by live timeout in testing |
