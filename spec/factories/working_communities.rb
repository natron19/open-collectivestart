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
