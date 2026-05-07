# Phase 6 — Seed Data & Final Polish

**Goal:** `rails db:seed` creates a demo-ready database with a realistic sample community and pre-generated starter pack. The README is updated. The app looks meaningful to a first-time visitor without requiring a Gemini API call.

**Depends on:** Phase 5 complete. Models, routes, controllers, views, and the AiTemplate seed all exist.

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §10–11

---

## Context

The seed data serves a specific purpose: a visitor who clones the repo and runs `bin/setup` should be able to visit the show page and see a complete, realistic starter pack without needing a Gemini API key. The hand-curated seed files look like real Gemini output. Only generating a *new* pack requires the API key.

The five seed files live in `db/seed_starter_pack/` and are committed to the repo. Keep them realistic — they represent what a real co-op founder would receive.

---

## 1. Seed Starter Pack Files

Create `db/seed_starter_pack/` with five files. The content below is representative — fill in realistic, co-op-appropriate copy:

### `db/seed_starter_pack/conversation_summary.md`

```markdown
> DRAFT FOR LAWYER REVIEW. This is a synthesis to react to, not a record of a conversation. Verify every claim with your team and a qualified co-op attorney before acting on it.

## Likely Shared Values

The North Tower Software Cooperative founding team appears to share a commitment to democratic ownership, sustainable livelihoods for technical workers, and service to mission-driven organizations. The choice of a worker cooperative structure—rather than a typical LLC or corporation—signals that member governance and equitable surplus distribution matter as much as revenue growth.

## Business Model Thinking the Team Will Need to Align On

The project-based model raises a key alignment question: how does the team price work, and who decides? A blended hourly rate shared among members simplifies billing but requires agreement on what "a fair rate" means for members with different experience levels. The team should discuss whether all members bill at the same rate or whether a rate ladder exists, and how surplus distribution (by hours worked) interacts with that choice.

## Capital Plan Considerations

Worker cooperatives typically require member equity contributions—sometimes called membership shares or member loans—as initial capitalization. With five founding members, the team should decide the minimum contribution per member, whether sweat equity counts, and what happens when a member exits (return of equity, transfer to incoming member, or buyout). No outside investor equity is typical in a worker co-op; project revenue and member contributions are the primary capital sources.

## Governance Preferences

A five-member founding team in a services business suggests a relatively flat governance structure is feasible. One member, one vote on major decisions (admission of new members, surplus distribution policy, major contracts) with a designated managing director for day-to-day operations is a common pattern for teams this size in Massachusetts.

## Member Commitments

Members of a services cooperative typically commit to: maintaining billable work through the co-op (not freelancing the same client types independently), attending governance meetings (monthly or quarterly), contributing to overhead (administrative work, business development), and holding their membership share for an agreed minimum period before requesting an exit.
```

### `db/seed_starter_pack/business_model_canvas.md`

```markdown
> DRAFT FOR LAWYER REVIEW. This canvas is a starting point for a founding conversation, not a finished business plan. Validate every assumption with your team and prospective members.

## Customer Segments

Mission-driven nonprofits in the Northeast US seeking custom internal tools. Likely segments: mid-size nonprofits (10–150 staff) with specific operational software needs that off-the-shelf tools don't address—donor management integrations, volunteer coordination systems, impact tracking dashboards.

## Value Proposition

Custom software built by a worker-owned team that understands mission-driven work, billed at transparent rates, with no venture-capital exit pressure. The co-op model means clients deal with member-owners, not account managers rotating off projects.

## Channels

Direct relationships from founders' existing nonprofit networks. Secondary: referrals from co-op network peers (USFWC members, co-op development centers), conference presence at nonprofit technology events (NTEN, OpenGov), and inbound from a public portfolio of past work.

## Member Relationships

Members govern the co-op through regular meetings and votes on policy, surplus distribution, and new member admission. Day-to-day project work is collaborative; members may pair on projects or lead independently depending on scope. A rotating facilitation role (rather than a permanent CEO) is common at this team size.

## Revenue Streams

Project-based fees billed at a blended hourly rate. Retainer engagements for ongoing maintenance and support are a secondary stream and improve revenue predictability. No product revenue or recurring SaaS fees in the initial model.

## Key Activities

Custom software development, client discovery and scoping, project management, member governance meetings, business development, and overhead administration (invoicing, bookkeeping, insurance).

## Key Resources

Member expertise in software development and nonprofit operations. Client relationships held by founding members. Co-op legal structure and operating agreement. A shared project management system and client communication workflow.

## Ownership Structure

Each founding member holds one membership share, acquired through an initial equity contribution (amount to be determined by the founding team). New members are admitted by a vote of existing members and must purchase a membership share. Exiting members have their share returned or transferred to an incoming member. No outside investors; the co-op is 100% member-owned.

## Cost and Capital Structure

Primary costs: member draws (distributions), payroll taxes, professional liability insurance, software subscriptions, and accounting. Initial capitalization from founding member equity contributions. Working capital reserve target: three months of overhead before accepting first client project.
```

### `db/seed_starter_pack/legal_form_comparison.md`

```markdown
> DRAFT FOR LAWYER REVIEW. Legal form selection is jurisdiction-specific and depends on facts not in this prompt. Do not file anything based on this comparison. Use it to prepare questions for a qualified co-op attorney in your jurisdiction.

## Worker Cooperative (Preferred by the Team)

**Governance structure:** One member, one vote on major decisions. Members elect a board (or govern directly at this team size). Massachusetts has a worker cooperative statute (M.G.L. Chapter 157A) that provides a clear legal framework.

**Capital implications:** Member equity contributions required. Surplus distributed as patronage based on labor contribution (hours or wages), not equity stake. External investor equity is structurally difficult and not typical.

**Tax treatment:** Pass-through taxation (like a partnership) if organized as a cooperative corporation. Patronage dividends paid to members may be deductible at the co-op level and taxable to members. Consult a CPA familiar with cooperative tax law—Subchapter T of the IRC applies.

**Member liability:** Limited liability for members, same as an LLC or corporation. Members are not personally liable for co-op debts.

**Exit mechanics:** Member sells or returns their membership share. The co-op's operating agreement should specify the buyout price (often par value or book value) and timeline. No open market for shares.

**One signature risk:** The Massachusetts worker co-op statute is relatively newer and less tested in litigation than LLC statutes. Some attorneys may recommend an LLC with a custom operating agreement that mimics co-op governance instead.

---

## Multi-Member LLC (Comparison Form)

**Governance structure:** Flexible—can be member-managed or manager-managed. An LLC operating agreement can replicate one-member-one-vote governance, but it requires careful drafting. No statutory default that mirrors co-op principles.

**Capital implications:** Flexible membership interest structure. Can accommodate outside investors more easily than a co-op corporation, which may be a risk to democratic ownership if future financing is needed.

**Tax treatment:** Pass-through taxation by default. Profit and loss allocated per the operating agreement—does not have to follow ownership percentage, but patronage-based allocation requires explicit drafting.

**Member liability:** Limited liability for all members.

**Exit mechanics:** Governed entirely by the operating agreement. Can be designed to require member approval of any transfer. More flexible than a co-op statute but requires more drafting to achieve the same protective effect.

**One signature risk:** Without a statute enforcing co-op principles, governance drift is possible if the operating agreement is not carefully maintained. New members admitted through standard LLC interest transfers may dilute democratic culture without legal backstop.

---

## Benefit Corporation (Comparison Form)

**Governance structure:** Standard corporate governance (board of directors, officers, shareholders). One share, one vote unless the charter specifies otherwise. Democratic ownership would require a specific share structure.

**Capital implications:** Can issue multiple classes of stock. More compatible with outside investment than a co-op, which may conflict with the team's worker-ownership goals.

**Tax treatment:** C-corporation taxation by default—double taxation on distributions. An S-corp election is possible but adds complexity and restricts ownership types.

**Member liability:** Limited liability for shareholders.

**Exit mechanics:** Shares sold on an open market (if any exists) or via private transfer. Exit is straightforward but does not protect against non-member acquisition.

**One signature risk:** Benefit corporation status addresses social purpose but does not create worker ownership. A benefit corporation with one founding-team shareholder holding a majority is not a worker cooperative in any meaningful governance sense. This form is listed for completeness but is unlikely to serve the team's stated goals.
```

### `db/seed_starter_pack/open_questions.md`

```markdown
1. What is the minimum equity contribution each founding member will make, and what happens to that capital if a member exits in the first two years?

2. How will the team handle a project that requires skills only one member has—does that member bill at a higher rate, or does the blended rate absorb the premium?

3. Massachusetts has a worker cooperative statute (M.G.L. Chapter 157A), but it was enacted in 1982 and has limited case law; will the team use this statute or form an LLC with a co-op-style operating agreement, and who will advise on that choice?
```

### `db/seed_starter_pack/gemini_raw.md`

Concatenate all four sections with their delimiters, matching the format Gemini actually returns. This is stored in `gemini_raw` and displayed via the "Show raw response" toggle.

```markdown
=== ARTIFACT 1: FOUNDING CONVERSATION SUMMARY ===
> DRAFT FOR LAWYER REVIEW. This is a synthesis to react to, not a record of a conversation. Verify every claim with your team and a qualified co-op attorney before acting on it.

[... paste full content of conversation_summary.md here ...]

=== ARTIFACT 2: COOPERATIVE BUSINESS MODEL CANVAS ===
> DRAFT FOR LAWYER REVIEW. This canvas is a starting point for a founding conversation, not a finished business plan. Validate every assumption with your team and prospective members.

[... paste full content of business_model_canvas.md here ...]

=== ARTIFACT 3: LEGAL FORM COMPARISON ===
> DRAFT FOR LAWYER REVIEW. Legal form selection is jurisdiction-specific and depends on facts not in this prompt. Do not file anything based on this comparison. Use it to prepare questions for a qualified co-op attorney in your jurisdiction.

[... paste full content of legal_form_comparison.md here ...]

=== OPEN QUESTIONS ===
> Three questions this team should answer before going further.

[... paste full content of open_questions.md here ...]
```

---

## 2. Update `db/seeds.rb` — Domain Seeds

Add after the AiTemplate seed block from Phase 4:

```ruby
# Domain seed — sample working community
demo_user = User.find_by!(email: "demo@example.com")

community = demo_user.working_communities.find_or_create_by!(name: "North Tower Software Cooperative") do |c|
  c.purpose = "A worker cooperative that builds and maintains custom internal tools for " \
              "mission-driven nonprofits in the Northeast US. We want stable, fairly-paid " \
              "engineering work and member-owners who set their own rates and choose their " \
              "own clients."
  c.jurisdiction         = "Massachusetts"
  c.founding_team_size   = 5
  c.business_model       = "Project-based custom software development for nonprofits, billed at a " \
                           "blended hourly rate. Each project staffs two to three members. Members " \
                           "share overhead and split distributable surplus by hours worked."
  c.legal_form_preference = "worker_coop"
end

unless community.founding_starter_pack
  community.create_founding_starter_pack!(
    conversation_summary:  File.read(Rails.root.join("db/seed_starter_pack/conversation_summary.md")),
    business_model_canvas: File.read(Rails.root.join("db/seed_starter_pack/business_model_canvas.md")),
    legal_form_comparison: File.read(Rails.root.join("db/seed_starter_pack/legal_form_comparison.md")),
    open_questions:        File.read(Rails.root.join("db/seed_starter_pack/open_questions.md")),
    gemini_raw:            File.read(Rails.root.join("db/seed_starter_pack/gemini_raw.md")),
    generated_at:          Time.current
  )
end
```

---

## 3. Update `README.md`

Add or replace the following sections in `README.md`. Keep the boilerplate's existing Stack, Setup, and License sections unchanged.

### App title and tagline (top of file)

```markdown
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

[Screenshot of the community show page with the three tabs and the yellow
lawyer-review alert. Replace this line with the screenshot once recorded.]
```

### "Why I built this" section

```markdown
## Why I built this

I'm building CollectiveStart, a multi-tenant SaaS suite for forming and
running working communities. The full app handles member onboarding,
governance, decision records, OWNERS health assessments, and operating
documents. This demo isolates the founding engine: the moment a team
sits down with a half-formed idea and wants something to react to.

I open sourced it because the founding conversation is where the
loneliness of co-op formation hurts most, and a working draft to react
to is more useful than another blog post. If you fork this and adapt the
prompt for your jurisdiction or your kind of working community, send me
the diff.
```

### "Tunable AI prompt" section

```markdown
## Tunable AI prompt

The Gemini prompt that generates the Founding Starter Pack is editable
without redeploying. Sign in as the seeded admin user
(`demo@example.com` / `password123`), navigate to `/admin/ai_templates`,
and open the `collectivestart_starter_pack_v1` record. The editor has a
live test panel: type sample variable values, click Test, see Gemini's
response inline, save when you're happy.

If you change the prompt and want your changes preserved across
`db:seed` runs, copy the updated text back into
`db/seed_prompts/collectivestart_starter_pack_v1_system.txt`.

The demo runs without a Gemini API key for the show-page tour — the
seed data is pre-generated. You only need the API key when generating a
new pack.
```

---

## Manual Checks — Phase 6

- [ ] `rails db:seed` on a fresh database (after `rails db:drop db:create db:migrate`) — completes without errors
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Dashboard shows "North Tower Software Cooperative"
- [ ] Click the community → show page renders all three tabs with realistic content (no API call required)
- [ ] "Show raw response" collapse reveals the `gemini_raw` text
- [ ] Yellow lawyer-review alert is present
- [ ] `rails db:seed` again on an existing database — idempotent (no errors, no duplicate records)
- [ ] Visit `/admin/ai_templates` — both `collectivestart_starter_pack_v1` and `health_ping` are listed
- [ ] Visit `/up` → `{"status":"ok"}` (Rails health check, no API needed)
- [ ] Visit `/up/llm` → requires valid `GEMINI_API_KEY`; returns `{"status":"ok"}` with valid key
- [ ] `README.md` shows the CollectiveStart title and tagline at the top
