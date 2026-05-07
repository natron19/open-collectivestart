# Phase 3 — WorkingCommunity CRUD

**Goal:** Signed-in users can create, list, view, edit, and delete their working communities. Unauthenticated requests and cross-user access are blocked. The show page renders an empty-state section ready for Turbo Stream targeting in Phase 5. No AI generation yet.

**Depends on:** Phase 2 complete (models and migrations exist). Phase 1 complete (nav link placeholder in layout).

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §4–6

**Reference docs to read first:**
- `docs/turbo-stimulus-patterns.md` — Stimulus controller pattern for the character counter
- `CLAUDE.md` — "TURBO STREAM: ALWAYS update(), NEVER replace()" and "NO PLAIN JAVASCRIPT — STIMULUS ONLY"

---

## 1. Routes

In `config/routes.rb`, replace any placeholder `working_communities` route with:

```ruby
resources :working_communities do
  resource :founding_starter_pack, only: [:create]
end
```

This generates the seven community routes plus `POST /working_communities/:working_community_id/founding_starter_pack`.

---

## 2. `WorkingCommunitiesController`

`app/controllers/working_communities_controller.rb`:

```ruby
class WorkingCommunitiesController < ApplicationController
  before_action :set_community, only: [:show, :edit, :update, :destroy]

  def index
    @communities = current_user.working_communities.order(created_at: :desc)
  end

  def new
    @community = current_user.working_communities.new
  end

  def create
    @community = current_user.working_communities.new(community_params)
    if @community.save
      redirect_to @community, notice: "Working community created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @community = current_user.working_communities
                             .includes(:founding_starter_pack)
                             .find(params[:id])
  end

  def edit; end

  def update
    if @community.update(community_params)
      redirect_to @community, notice: "Community updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @community.destroy
    redirect_to working_communities_path, notice: "Community deleted."
  end

  private

  def set_community
    @community = current_user.working_communities.find(params[:id])
  end

  def community_params
    params.require(:working_community).permit(
      :name, :purpose, :jurisdiction, :founding_team_size,
      :business_model, :legal_form_preference
    )
  end
end
```

**Key pattern:** All queries go through `current_user.working_communities`. If the record exists but belongs to a different user, `find` raises `ActiveRecord::RecordNotFound`, which the boilerplate's `ApplicationController` already handles by rendering 404. Never use `WorkingCommunity.find(params[:id])` directly.

---

## 3. Shared Partial: `_communities_list.html.erb`

`app/views/working_communities/_communities_list.html.erb`:

Renders one Bootstrap card per community. Empty state when the collection is empty.

```erb
<% if communities.any? %>
  <div class="row row-cols-1 g-3">
    <% communities.each do |community| %>
      <div class="col">
        <div class="card">
          <div class="card-body d-flex justify-content-between align-items-center">
            <div>
              <h5 class="card-title mb-1"><%= community.name %></h5>
              <div class="d-flex gap-2 flex-wrap">
                <span class="badge bg-secondary"><%= community.jurisdiction %></span>
                <span class="badge bg-secondary"><%= community.founding_team_size %> founders</span>
                <span class="badge bg-secondary"><%= community.legal_form_preference.humanize %></span>
              </div>
            </div>
            <%= link_to "View", community, class: "btn btn-primary btn-sm" %>
          </div>
        </div>
      </div>
    <% end %>
  </div>
<% else %>
  <div class="card text-center py-5">
    <div class="card-body">
      <p class="text-muted mb-3">No working communities yet. Sketch your first one to get a starter pack.</p>
      <%= link_to "New Working Community", new_working_community_path, class: "btn btn-primary" %>
    </div>
  </div>
<% end %>
```

---

## 4. `working_communities/index.html.erb`

```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>My Working Communities</h1>
    <%= link_to "New Working Community", new_working_community_path, class: "btn btn-primary" %>
  </div>
  <%= render "communities_list", communities: @communities %>
</div>
```

---

## 5. `dashboard/show.html.erb` (replace boilerplate)

```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Welcome, <%= current_user.first_name %></h1>
    <%= link_to "New Working Community", new_working_community_path, class: "btn btn-primary" %>
  </div>
  <%= render "working_communities/communities_list", communities: current_user.working_communities.order(created_at: :desc) %>
</div>
```

---

## 6. Form Partial: `working_communities/_form.html.erb`

```erb
<%= form_with model: community, class: "needs-validation" do |f| %>
  <% if community.errors.any? %>
    <div class="alert alert-danger">
      <ul class="mb-0">
        <% community.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-3">
    <%= f.label :name, class: "form-label" %>
    <%= f.text_field :name, class: "form-control #{"is-invalid" if community.errors[:name].any?}" %>
  </div>

  <div class="mb-3">
    <%= f.label :purpose, class: "form-label" %>
    <div data-controller="character-counter">
      <%= f.text_area :purpose, rows: 5,
            class: "form-control #{"is-invalid" if community.errors[:purpose].any?}",
            data: { character_counter_target: "field" } %>
      <div class="character-counter text-muted small text-end mt-1">
        <span data-character-counter-target="count">0</span> / 1500
      </div>
    </div>
  </div>

  <div class="mb-3">
    <%= f.label :jurisdiction, class: "form-label" %>
    <%= f.text_field :jurisdiction,
          class: "form-control #{"is-invalid" if community.errors[:jurisdiction].any?}",
          placeholder: "e.g. Massachusetts, France, or 'unsure'" %>
    <div class="form-text">US state name, country name, or "unsure" if undecided.</div>
  </div>

  <div class="mb-3">
    <%= f.label :founding_team_size, class: "form-label" %>
    <%= f.number_field :founding_team_size, min: 2, max: 50,
          class: "form-control #{"is-invalid" if community.errors[:founding_team_size].any?}" %>
  </div>

  <div class="mb-3">
    <%= f.label :business_model, class: "form-label" %>
    <div data-controller="character-counter">
      <%= f.text_area :business_model, rows: 5,
            class: "form-control #{"is-invalid" if community.errors[:business_model].any?}",
            data: { character_counter_target: "field" } %>
      <div class="character-counter text-muted small text-end mt-1">
        <span data-character-counter-target="count">0</span> / 1500
      </div>
    </div>
  </div>

  <div class="mb-3">
    <%= f.label :legal_form_preference, class: "form-label" %>
    <%= f.select :legal_form_preference,
          [
            ["Worker Cooperative",          "worker_coop"],
            ["Multi-Stakeholder Cooperative","multi_stakeholder_coop"],
            ["Employee-Owned LLC",          "employee_owned_llc"],
            ["Benefit Corporation",         "benefit_corporation"],
            ["Unsure — help me decide",     "unsure"]
          ],
          { include_blank: "Select a legal form..." },
          class: "form-select #{"is-invalid" if community.errors[:legal_form_preference].any?}" %>
  </div>

  <div class="d-flex gap-2">
    <%= f.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", working_communities_path, class: "btn btn-link" %>
  </div>
<% end %>
```

---

## 7. `new.html.erb` and `edit.html.erb`

```erb
<%# new.html.erb %>
<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col-lg-7">
      <h1 class="mb-4">New Working Community</h1>
      <%= render "form", community: @community %>
    </div>
  </div>
</div>
```

```erb
<%# edit.html.erb %>
<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col-lg-7">
      <h1 class="mb-4">Edit <%= @community.name %></h1>
      <%= render "form", community: @community %>
    </div>
  </div>
</div>
```

---

## 8. Show Page — Empty State (Phase 3 version)

`app/views/working_communities/show.html.erb` — Phase 3 version with empty-state only. Phase 5 will add the pack-present state. The `id="starter-pack-section"` div must be present now so Turbo Stream can target it later.

```erb
<div class="container py-4">
  <%# Persistent lawyer-review alert — always visible %>
  <div class="alert alert-warning lawyer-review-banner" role="alert">
    <strong>For lawyer review.</strong> Every artifact below is a working draft, never a filing-ready document. CollectiveStart helps you think; it does not give legal advice.
  </div>

  <%# Header %>
  <div class="d-flex justify-content-between align-items-start mb-4">
    <div>
      <h1 class="mb-2"><%= @community.name %></h1>
      <div class="d-flex gap-2 flex-wrap">
        <span class="badge bg-secondary"><%= @community.jurisdiction %></span>
        <span class="badge bg-secondary"><%= @community.founding_team_size %> founders</span>
        <span class="badge bg-secondary"><%= @community.legal_form_preference.humanize %></span>
      </div>
    </div>
    <div class="d-flex gap-2 flex-wrap justify-content-end">
      <%= link_to "Edit", edit_working_community_path(@community), class: "btn btn-outline-secondary btn-sm" %>
      <%= button_to "Delete", @community, method: :delete,
            class: "btn btn-outline-danger btn-sm",
            data: { turbo_confirm: "Delete this community and its starter pack?" } %>
      <%= button_to "Generate Starter Pack",
            working_community_founding_starter_pack_path(@community),
            method: :post,
            class: "btn btn-primary btn-sm" %>
    </div>
  </div>

  <%# Starter pack section — Turbo Stream target %>
  <div id="starter-pack-section">
    <div class="card text-center py-5">
      <div class="card-body">
        <h5 class="card-title">No starter pack yet</h5>
        <p class="text-muted mb-4">
          Generate your Founding Starter Pack to get a founding conversation summary,
          a cooperative business model canvas, and a legal form comparison.
        </p>
        <%= button_to "Generate Starter Pack",
              working_community_founding_starter_pack_path(@community),
              method: :post,
              class: "btn btn-primary" %>
      </div>
    </div>
  </div>
</div>
```

---

## 9. Stimulus: `character-counter` Controller

`app/javascript/controllers/character_counter_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "count"]

  connect() {
    this.update()
  }

  update() {
    this.countTarget.textContent = this.fieldTarget.value.length
  }
}
```

Register it in `app/javascript/controllers/index.js`:

```javascript
import CharacterCounterController from "./character_counter_controller"
application.register("character-counter", CharacterCounterController)
```

Add the action descriptor to the textarea in the form:

```erb
data: { character_counter_target: "field", action: "input->character-counter#update" }
```

---

## 10. CSS

Add to `app/assets/stylesheets/application.css`:

```css
.character-counter {
  font-size: 0.8rem;
}

.lawyer-review-banner {
  border-left: 4px solid var(--accent);
}
```

---

## RSpec Tests — Phase 3

**`spec/requests/working_communities_spec.rb`**

```ruby
RSpec.describe "WorkingCommunities", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let!(:community) { create(:working_community, user: user) }

  # --- Unauthenticated access ---
  it "redirects unauthenticated user from index" do
    get working_communities_path
    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects unauthenticated user from show" do
    get working_community_path(community)
    expect(response).to redirect_to(sign_in_path)
  end

  # --- Index ---
  it "returns 200 for signed-in user" do
    sign_in_as(user)
    get working_communities_path
    expect(response).to have_http_status(:ok)
  end

  it "only shows the current user's communities" do
    other_community = create(:working_community, user: other, name: "Other Co-op")
    sign_in_as(user)
    get working_communities_path
    expect(response.body).to include(community.name)
    expect(response.body).not_to include("Other Co-op")
  end

  # --- New ---
  it "returns 200 for new form" do
    sign_in_as(user)
    get new_working_community_path
    expect(response).to have_http_status(:ok)
  end

  # --- Create ---
  it "creates a community with valid params and redirects to show" do
    sign_in_as(user)
    expect {
      post working_communities_path, params: { working_community: attributes_for(:working_community) }
    }.to change(WorkingCommunity, :count).by(1)
    expect(response).to redirect_to(working_community_path(WorkingCommunity.last))
  end

  it "re-renders new with 422 on invalid params" do
    sign_in_as(user)
    post working_communities_path, params: { working_community: { name: "x" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  # --- Show ---
  it "returns 200 for the owner" do
    sign_in_as(user)
    get working_community_path(community)
    expect(response).to have_http_status(:ok)
  end

  it "returns 404 for a non-owner" do
    sign_in_as(other)
    get working_community_path(community)
    expect(response).to have_http_status(:not_found)
  end

  # --- Edit ---
  it "returns 200 for the owner" do
    sign_in_as(user)
    get edit_working_community_path(community)
    expect(response).to have_http_status(:ok)
  end

  it "returns 404 for a non-owner on edit" do
    sign_in_as(other)
    get edit_working_community_path(community)
    expect(response).to have_http_status(:not_found)
  end

  # --- Update ---
  it "updates community and redirects to show for owner" do
    sign_in_as(user)
    patch working_community_path(community), params: { working_community: { name: "Updated Name" } }
    expect(response).to redirect_to(working_community_path(community))
    expect(community.reload.name).to eq("Updated Name")
  end

  it "returns 404 for non-owner on update" do
    sign_in_as(other)
    patch working_community_path(community), params: { working_community: { name: "Hijacked" } }
    expect(response).to have_http_status(:not_found)
  end

  # --- Destroy ---
  it "deletes the community and redirects for owner" do
    sign_in_as(user)
    expect {
      delete working_community_path(community)
    }.to change(WorkingCommunity, :count).by(-1)
    expect(response).to redirect_to(working_communities_path)
  end

  it "returns 404 for non-owner on destroy" do
    sign_in_as(other)
    expect {
      delete working_community_path(community)
    }.not_to change(WorkingCommunity, :count)
    expect(response).to have_http_status(:not_found)
  end
end
```

---

## Manual Checks — Phase 3

Run `rails server` in a separate terminal.

- [ ] Sign in → dashboard shows empty state with "New Working Community" button
- [ ] Click "New Working Community" → form renders with all 6 fields
- [ ] Submit form with all valid fields → redirects to show page; empty-state pack card visible
- [ ] Show page has the yellow lawyer-review alert at the top
- [ ] Show page has Edit, Delete, and "Generate Starter Pack" buttons in the action toolbar
- [ ] Navbar "My Communities" link → lists the community just created
- [ ] Dashboard also shows the community card
- [ ] Character counter updates as you type in Purpose and Business Model fields
- [ ] Submit with a name shorter than 2 characters → form re-renders with error, no redirect
- [ ] Submit with Purpose shorter than 50 characters → form re-renders with error
- [ ] Edit a community → change name → save → redirected to show with updated name
- [ ] Click Delete → confirm dialog → community removed → redirected to list
- [ ] Sign out → sign in as a different user → try to visit the first user's community URL directly → 404
