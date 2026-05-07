# Phase 1 — App Configuration & Branding

**Goal:** The app boots with CollectiveStart branding. No new models, no routes, no controllers. This phase is pure configuration and copy.

**Depends on:** Open Demo Starter boilerplate is installed and `rails server` starts without errors.

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §2

---

## Context

The boilerplate ships with placeholder env vars, a default blue accent color, a stub home page, and a stub dashboard. This phase replaces all of those with CollectiveStart-specific values. Every app name, tagline, and description must come from `ENV.fetch(...)` — never hardcoded.

---

## 1. Environment Variables

Update `.env` (local only, gitignored) and `.env.example` (committed, no real values):

```
APP_NAME=CollectiveStart Demo
APP_TAGLINE=Tell me about your working community. Get your founding starter pack.
APP_DESCRIPTION=An open source demo of the CollectiveStart founding engine. Sketch a working community in one form, get a draft starter pack with three artifacts.
```

`.env.example` already has the keys — just update the placeholder values to match the above. Do not set real API keys in `.env.example`.

---

## 2. Accent Color

In `app/assets/stylesheets/application.css`, update the CSS custom properties in `:root`:

```css
:root {
  --accent: #0f766e;
  --accent-hover: #0d5e58;
}
```

The boilerplate ships with a default blue. Replace both values. No other CSS changes needed in this phase.

---

## 3. Navbar — "My Communities" Link

In `app/views/layouts/application.html.erb`, add a nav link for signed-in users. Follow the existing pattern for authenticated nav links (the admin link is a good reference for placement):

```erb
<% if signed_in? %>
  <%= link_to "My Communities", working_communities_path, class: "nav-link" %>
<% end %>
```

The route `working_communities_path` will raise a `NoMethodError` until Phase 3 adds the routes. That is expected and acceptable — the nav link will be inert until then. Add the route stub now anyway so the link renders without errors by adding a placeholder route if needed, or simply defer until Phase 3.

> **Safer option for Phase 1:** wrap the link in a `begin/rescue` or check `respond_to?(:working_communities_path)`. Or just add the route stub: `get "/working_communities", to: "working_communities#index"` in `config/routes.rb` now (the controller doesn't need to exist yet — routing errors are fine at this stage).

---

## 4. Home Page

Replace `app/views/home/index.html.erb` entirely. The new page must:

1. **Hero section** — display `ENV.fetch("APP_TAGLINE", "")` in a large heading. Use Bootstrap's `display-4` or `display-5` class.
2. **Explanation paragraph** — one paragraph explaining what the Founding Starter Pack is. Write it directly in the view (no ENV variable needed for body copy).
3. **Three preview cards** — one Bootstrap card each for:
   - **Founding Conversation Summary** — "A synthesis of the team's founding conversation: values, governance, capital, and member commitments."
   - **Cooperative Business Model Canvas** — "Nine adapted canvas sections built for a member-owned firm, not a VC-backed startup."
   - **Legal Form Comparison** — "A trade-off comparison of the three legal forms most plausible for the team's jurisdiction and goals."
4. **Primary CTA** — conditional:
   - Guest (not signed in): `link_to "Sign up", sign_up_path, class: "btn btn-primary btn-lg"`
   - Signed in: `link_to "Go to dashboard", dashboard_path, class: "btn btn-primary btn-lg"`

Example structure:

```erb
<div class="container py-5">
  <div class="text-center mb-5">
    <h1 class="display-5 fw-bold"><%= ENV.fetch("APP_TAGLINE", "CollectiveStart Demo") %></h1>
    <p class="lead text-muted mt-3"><!-- explanation paragraph --></p>
    <div class="mt-4">
      <% if signed_in? %>
        <%= link_to "Go to dashboard", dashboard_path, class: "btn btn-primary btn-lg" %>
      <% else %>
        <%= link_to "Sign up", sign_up_path, class: "btn btn-primary btn-lg" %>
      <% end %>
    </div>
  </div>

  <div class="row g-4">
    <!-- three preview cards -->
  </div>
</div>
```

---

## Manual Checks — Phase 1

Run `rails server` in a separate terminal. Do not start it here.

- [ ] Visit `http://localhost:3000` — hero tagline reads "Tell me about your working community. Get your founding starter pack."
- [ ] Navbar shows "My Communities" link when signed in (may show routing error if clicked — that is expected until Phase 3)
- [ ] Three preview artifact cards are visible on the home page
- [ ] Guest sees "Sign up" CTA; signed-in user sees "Go to dashboard" CTA
- [ ] Primary buttons use the teal accent color (`#0f766e`), not the default blue
- [ ] Page source shows `data-bs-theme="dark"` on the `<html>` element (boilerplate sets this — verify it is unchanged)
- [ ] `.env.example` is committed; `.env` is not tracked by git (`git status` should not show `.env`)
