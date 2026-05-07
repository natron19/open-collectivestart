# Phase 7 — Full Test Suite, QA & Pre-Publish Security

**Goal:** All RSpec specs pass with zero real API calls. One targeted system spec covers the tabbed show page. The full QA matrix is run manually. The pre-publish security check passes before the repo goes public on GitHub.

**Depends on:** Phases 1–6 complete.

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §9

**Reference docs to read first:**
- `docs/testing.md` — RSpec helper setup, Capybara config, Gemini stubbing
- `docs/prompts/pre-publish-security-check.md` — the security prompt to run before publishing

---

## 1. System Spec: Community Show Tabs

`spec/system/community_show_tabs_spec.rb`

Capybara + Chrome headless. Uses a seeded `WorkingCommunity` with a pre-built `FoundingStarterPack` (no Gemini call).

**Setup** — add to `Gemfile` test group if not already present:

```ruby
group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

Create `spec/support/capybara.rb`:

```ruby
require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :chrome_headless
```

Require it in `spec/rails_helper.rb` (should be auto-loaded if you have `Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }` in rails_helper).

**Spec:**

```ruby
require "rails_helper"

RSpec.describe "Community show page — tabs", type: :system, js: true do
  let(:user)      { create(:user) }
  let(:community) { create(:working_community, :with_pack, user: user) }

  before do
    # Sign in via the session form (system spec — full browser)
    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
    visit working_community_path(community)
  end

  it "renders all three tab headings" do
    expect(page).to have_content("Founding Conversation")
    expect(page).to have_content("Business Model Canvas")
    expect(page).to have_content("Legal Form Comparison")
  end

  it "shows the default tab content on load" do
    within("#pane-conversation") do
      expect(page).to have_content(community.founding_starter_pack.conversation_summary.first(50).gsub(/\s+/, " "))
    end
  end

  it "switches to Business Model Canvas tab and shows content" do
    click_button "Business Model Canvas"
    within("#pane-canvas") do
      expect(page).to have_content(community.founding_starter_pack.business_model_canvas.first(50).gsub(/\s+/, " "))
    end
  end

  it "updates URL with ?tab= parameter on tab switch" do
    click_button "Business Model Canvas"
    expect(page.current_url).to include("tab=business_model_canvas")
  end

  it "activates the correct tab when loaded with ?tab= param" do
    visit working_community_path(community, tab: "legal_form_comparison")
    expect(find("#tab-legal")["class"]).to include("active")
  end

  it "reveals raw response via collapse toggle" do
    click_link "Show raw response"
    expect(page).to have_css("#raw-response", visible: true)
    expect(page).to have_content(community.founding_starter_pack.gemini_raw.first(30))
  end

  it "keeps the lawyer-review alert visible on every tab" do
    expect(page).to have_css(".lawyer-review-banner")
    click_button "Business Model Canvas"
    expect(page).to have_css(".lawyer-review-banner")
    click_button "Legal Form Comparison"
    expect(page).to have_css(".lawyer-review-banner")
  end
end
```

---

## 2. Run Full RSpec Suite

Ask the user to run:

```bash
bundle exec rspec
```

Expected: zero failures. All specs from Phases 2–5 plus the system spec from this phase.

**Verify:** No real Gemini API calls. The output should not show any HTTP requests to `generativelanguage.googleapis.com`. If any appear, find the spec that is missing a `GeminiService` stub.

---

## 3. RuboCop

Ask the user to run:

```bash
bundle exec rubocop --autocorrect
```

Fix any remaining offenses. Common ones to check:
- Trailing whitespace in new view files
- Missing frozen string literal comments (if the project enforces them)
- Long lines in the parser service or controller

---

## 4. Manual QA — Golden Path

Run `rails server` in a separate terminal. Use a valid `GEMINI_API_KEY`.

- [ ] Guest visits `http://localhost:3000` → landing page with tagline, three preview cards, "Sign up" CTA
- [ ] Guest clicks "Sign up" → creates account → lands on dashboard (empty state with "New Working Community" button)
- [ ] Click "New Working Community" → fills all six fields → submits → redirected to show page with empty-state pack card
- [ ] Click "Generate Starter Pack" → pack appears inline via Turbo Stream (no full reload, verify via network tab)
- [ ] Yellow lawyer-review alert is above the tabs
- [ ] Click each tab → content renders as HTML (not raw markdown)
- [ ] "Open Questions" alert renders below the tabs
- [ ] Toggle "Show raw response" → `gemini_raw` text appears
- [ ] Footer shows generation timestamp
- [ ] Click "Business Model Canvas" tab → URL updates to `?tab=business_model_canvas`
- [ ] Reload with that URL → correct tab is active
- [ ] Click "Edit" → change a field → save → redirected to show; pack is not deleted
- [ ] Click "Regenerate Starter Pack" → pack is updated in place (verify with `rails console`: `FoundingStarterPack.count` stays at 1)
- [ ] Click "Delete" → confirm → community gone → redirected to list
- [ ] Sign out → "My Communities" nav link is absent → home page shows "Sign up" CTA

---

## 5. Manual QA — Edge Cases

- [ ] Create community with name `x` (1 char) → form validation error shown, no redirect
- [ ] Create community with purpose < 50 chars → validation error shown
- [ ] Create 26 communities for the same user (or set one user's count to 25 via console, then try to create one more) → "You can have at most 25 working communities" error
- [ ] Sign in as User A → visit User B's community URL → 404 (not redirect, not 403)
- [ ] Visit `/working_communities` without signing in → redirect to `/sign_in`
- [ ] Visit `/admin` as a non-admin user → 404
- [ ] Visit `/admin/ai_templates` as admin → `collectivestart_starter_pack_v1` is present; edit and use the test panel

---

## 6. Pre-Publish Security Check

**Before making the repo public on GitHub, run the following prompt in Claude Code.**

This step is mandatory. Read `docs/prompts/pre-publish-security-check.md` for the full prompt text, then execute it:

```
Perform a security review of this Rails app before it's published publicly on GitHub. Check every item below and report findings — safe or risky — with file path and line number for anything flagged.

**1. Hardcoded secrets**
Scan all files for hardcoded API keys, passwords, tokens, or secrets. Check: `.env`, `config/credentials.yml.enc`, `config/master.key`, `config/database.yml`, `config/secrets.yml`, `config/initializers/`, any `.key` files, and any file in `.kamal/`.

**2. Gitignore coverage**
Read `.gitignore` and confirm it excludes:
- `.env` and `.env.*`
- `config/master.key` and all `*.key` files
- `config/credentials.yml.enc`
- `log/` and `tmp/`
Report any of the above that are NOT covered.

**3. `.env.example`**
Read it and confirm every value is a placeholder (e.g. `your_key_here`), not a real value.

**4. `config/database.yml`**
Check for hardcoded username, password, or host. Production values should use `ENV.fetch(...)`.

**5. `db/seeds.rb`**
Check for hardcoded credentials beyond any intentional demo passwords that are documented in the README.

**6. `config/environments/production.rb`**
Check for hardcoded secrets. All sensitive values should use `ENV.fetch(...)`.

**7. Gemfile**
Confirm the only gem source is `https://rubygems.org`. Flag any private gem servers or `git:` sources pointing to private repos.

**8. README**
Check that it doesn't expose internal infrastructure details (internal URLs, server names, real email addresses, internal team names).

**9. Log and tmp files**
Confirm `log/` and `tmp/` contain no tracked files with sensitive content.

**10. Git history**
Run `git log --oneline` and check if any commit message suggests a secret was ever committed (e.g. "add API key", "fix credentials"). If so, flag it — the history would need to be scrubbed before publishing.

For each finding, state: file path, line number (if applicable), what the risk is, and what action to take. Fix any issues you can directly; flag anything that requires a manual step (like rotating a key).
```

**Security check acceptance criteria:**
- [ ] No hardcoded secrets in any committed file
- [ ] `.env` is in `.gitignore`; `.env.example` is committed with placeholder values only
- [ ] `config/master.key` is in `.gitignore`
- [ ] No sensitive content in `log/` or `tmp/`
- [ ] Git history contains no commit messages suggesting a secret was committed
- [ ] `demo@example.com` / `password123` credentials are documented in the README (intentional demo credentials — acceptable)

---

## Acceptance Criteria Summary

| Check | Verified |
|---|---|
| `bundle exec rspec` — zero failures | [ ] |
| Zero real Gemini API calls in test run | [ ] |
| `bundle exec rubocop` — zero offenses | [ ] |
| Golden path QA complete | [ ] |
| Edge case QA complete | [ ] |
| Pre-publish security check passed | [ ] |
| Repo is ready to push to GitHub | [ ] |
