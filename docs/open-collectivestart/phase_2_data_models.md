# Phase 2 — Data Models & Migrations

**Goal:** `WorkingCommunity` and `FoundingStarterPack` exist in the database with correct columns, indexes, associations, and validations. Factories exist. No controllers or views yet.

**Depends on:** Phase 1 complete. `rails db:migrate` has run. UUID primary keys and `pgcrypto` extension are already enabled from the boilerplate.

**Spec reference:** `docs/open-collectivestart/collectivestart-demo-spec.md` §3

---

## Context

All tables use UUID primary keys (`id: :uuid`). All timestamps are `null: false`. Foreign key columns use `type: :uuid`. Follow the boilerplate's database conventions exactly.

---

## 1. Migration: `working_communities`

```ruby
class CreateWorkingCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :working_communities, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,                   null: false
      t.text    :purpose,                null: false
      t.string  :jurisdiction,           null: false
      t.integer :founding_team_size,     null: false
      t.text    :business_model,         null: false
      t.string  :legal_form_preference,  null: false
      t.timestamps                        null: false
    end

    add_index :working_communities, :created_at
  end
end
```

---

## 2. Migration: `founding_starter_packs`

```ruby
class CreateFoundingStarterPacks < ActiveRecord::Migration[8.1]
  def change
    create_table :founding_starter_packs, id: :uuid do |t|
      t.references :working_community, null: false, foreign_key: true,
                                       type: :uuid, index: { unique: true }
      t.text     :conversation_summary
      t.text     :business_model_canvas
      t.text     :legal_form_comparison
      t.text     :open_questions
      t.text     :gemini_raw
      t.datetime :generated_at
      t.timestamps null: false
    end
  end
end
```

---

## 3. Model: `WorkingCommunity`

`app/models/working_community.rb`:

```ruby
class WorkingCommunity < ApplicationRecord
  LEGAL_FORM_OPTIONS = %w[
    worker_coop
    multi_stakeholder_coop
    employee_owned_llc
    benefit_corporation
    unsure
  ].freeze

  belongs_to :user
  has_one :founding_starter_pack, dependent: :destroy

  validates :name,                  presence: true, length: { in: 2..80 }
  validates :purpose,               presence: true, length: { in: 50..1500 }
  validates :jurisdiction,          presence: true, length: { in: 2..80 }
  validates :business_model,        presence: true, length: { in: 50..1500 }
  validates :founding_team_size,    presence: true,
                                    numericality: { only_integer: true, in: 2..50 }
  validates :legal_form_preference, presence: true,
                                    inclusion: { in: LEGAL_FORM_OPTIONS }

  validate :user_community_limit, on: :create

  private

  def user_community_limit
    return unless user
    if user.working_communities.count >= 25
      errors.add(:base, "You can have at most 25 working communities.")
    end
  end
end
```

---

## 4. Model: `FoundingStarterPack`

`app/models/founding_starter_pack.rb`:

```ruby
class FoundingStarterPack < ApplicationRecord
  belongs_to :working_community
  has_one :user, through: :working_community

  validates :working_community_id, presence: true, uniqueness: true
end
```

---

## 5. Update `User` Model

Add to `app/models/user.rb`:

```ruby
has_many :working_communities, dependent: :destroy
```

---

## 6. Factories

**`spec/factories/working_communities.rb`:**

```ruby
FactoryBot.define do
  factory :working_community do
    association :user
    name                  { "Test Software Cooperative" }
    purpose               { "A worker cooperative that builds custom software for nonprofits. " \
                            "We want stable, fairly-paid work with member-owned governance." }
    jurisdiction          { "Massachusetts" }
    founding_team_size    { 5 }
    business_model        { "Project-based custom software development billed at a blended hourly rate. " \
                            "Members share overhead and split distributable surplus by hours worked." }
    legal_form_preference { "worker_coop" }

    trait :with_pack do
      after(:create) do |community|
        create(:founding_starter_pack, working_community: community)
      end
    end
  end
end
```

**`spec/factories/founding_starter_packs.rb`:**

```ruby
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
```

---

## RSpec Tests — Phase 2

### `spec/models/working_community_spec.rb`

Cover all of the following:

**Validations — presence:**
- `name`, `purpose`, `jurisdiction`, `business_model`, `founding_team_size`, `legal_form_preference` are all required

**Validations — length:**
- `name` with 1 character fails; with 2 characters passes; with 80 characters passes; with 81 characters fails
- `purpose` with 49 characters fails; with 50 characters passes
- `business_model` with 49 characters fails; with 50 characters passes

**Validations — founding_team_size:**
- `1` fails; `2` passes; `50` passes; `51` fails; `"3"` (string) passes (Rails casts); `3.5` (float) fails

**Validations — legal_form_preference:**
- Each of the five valid values passes: `worker_coop`, `multi_stakeholder_coop`, `employee_owned_llc`, `benefit_corporation`, `unsure`
- An invalid value (`"banana"`) fails

**25-community cap:**
- A user with 24 communities can add a 25th (passes)
- A user with 25 communities cannot add a 26th (fails with the exact message "You can have at most 25 working communities.")
- The cap only fires on `create`, not `update`

**Associations:**
- `belongs_to :user` — community without a user is invalid
- `has_one :founding_starter_pack` — destroying the community destroys the pack (`dependent: :destroy`)

### `spec/models/founding_starter_pack_spec.rb`

- Valid with all four parsed fields nil and only `gemini_raw` present (parsed fields are optional)
- Invalid without `working_community_id`
- Unique constraint on `working_community_id` — second pack for the same community fails validation
- `founding_starter_pack.user` returns the community's user (through association)
- Destroying the parent `working_community` destroys the pack

---

## Manual Checks — Phase 2

Do not start rails server for these — use the console.

- [ ] `rails db:migrate` — exits without errors
- [ ] `rails db:migrate:status` — both new migrations show `up`
- [ ] `rails console`:
  ```ruby
  u = User.first # or create(:user) via factory in console
  c = u.working_communities.create!(
    name: "Sunrise Bakery Collective",
    purpose: "A worker-owned bakery serving our neighborhood with fresh bread " \
             "and fair wages for every member-owner.",
    jurisdiction: "Vermont",
    founding_team_size: 4,
    business_model: "Retail bakery selling direct to customers in a storefront " \
                    "and at two farmers markets. Members rotate weekend shifts.",
    legal_form_preference: "worker_coop"
  )
  c.persisted? # => true
  ```
- [ ] `rails console` — validation failure cases:
  ```ruby
  u.working_communities.create(name: "x").errors.full_messages
  # should include length error for name and presence errors for other fields
  u.working_communities.create(founding_team_size: 1).errors[:founding_team_size]
  # should include a range error
  u.working_communities.create(legal_form_preference: "llc").errors[:legal_form_preference]
  # should include inclusion error
  ```
- [ ] `rails console` — pack association:
  ```ruby
  pack = c.create_founding_starter_pack!(gemini_raw: "test raw", generated_at: Time.current)
  pack.user == u # => true
  c.destroy
  FoundingStarterPack.find_by(id: pack.id) # => nil (destroyed by cascade)
  ```
