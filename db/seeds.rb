# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_initialize_by(name: "health_ping").tap do |t|
  t.assign_attributes(
    description:          "Minimal prompt used by the /up/llm health check endpoint.",
    system_prompt:        "You are a health check endpoint. Respond with exactly: ok",
    user_prompt_template: "ping",
    model:                "gemini-2.5-flash",
    max_output_tokens:    10,
    temperature:          0.0,
    notes:                "Do not modify. Used by HealthController#llm."
  )
  t.save!
end

puts "Seeded: health_ping AI template"

# Placeholder demo template — each demo app replaces this
AiTemplate.find_or_initialize_by(name: "demo_placeholder_v1").tap do |t|
  t.assign_attributes(
    description:          "Starter template. Replace with your demo's actual prompt.",
    system_prompt:        "You are a helpful assistant.",
    user_prompt_template: "Please help me with: {{request}}",
    model:                "gemini-2.5-flash",
    max_output_tokens:    2000,
    temperature:          0.7,
    notes:                "Starter template. Replace this in your demo app's seeds.rb."
  )
  t.save!
end

puts "Seeded: demo_placeholder_v1 AI template"

# CollectiveStart founding starter pack template
AiTemplate.find_or_initialize_by(name: "collectivestart_starter_pack_v1").tap do |t|
  t.assign_attributes(
    description:          "Founding Starter Pack for a working community: " \
                          "founding conversation, business model canvas, " \
                          "legal form comparison, plus three open questions.",
    system_prompt:        File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_system.txt")),
    user_prompt_template: File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_user.txt")),
    model:                "gemini-2.5-flash",
    max_output_tokens:    8192,
    temperature:          0.4,
    notes:                File.read(Rails.root.join("db/seed_prompts/collectivestart_starter_pack_v1_notes.txt"))
  )
  t.save!
end

puts "Seeded: collectivestart_starter_pack_v1 AI template"

# CollectiveStart demo community with pre-generated starter pack
demo_user = User.find_by!(email: "demo@example.com")

community = WorkingCommunity.find_or_create_by!(
  user: demo_user,
  name: "North Tower Software Cooperative"
) do |c|
  c.purpose               = "Build custom software for mission-driven nonprofits in the Northeast US. " \
                            "We want to create sustainable livelihoods for technical workers while " \
                            "serving organizations doing real good in their communities."
  c.business_model        = "Project-based custom software development billed at a blended hourly rate. " \
                            "Secondary stream: retainer engagements for ongoing maintenance and support. " \
                            "No product revenue or recurring SaaS in the initial model."
  c.founding_team_size    = 5
  c.legal_form_preference = "worker_coop"
  c.jurisdiction          = "Massachusetts"
end

puts "Seeded: North Tower Software Cooperative (working community)"

unless community.founding_starter_pack
  seed_dir = Rails.root.join("db/seed_starter_pack")

  community.create_founding_starter_pack!(
    conversation_summary: File.read(seed_dir.join("conversation_summary.md")),
    business_model_canvas: File.read(seed_dir.join("business_model_canvas.md")),
    legal_form_comparison: File.read(seed_dir.join("legal_form_comparison.md")),
    open_questions: File.read(seed_dir.join("open_questions.md")),
    gemini_raw: File.read(seed_dir.join("gemini_raw.md")),
    generated_at: Time.current
  )

  puts "Seeded: Founding Starter Pack for North Tower Software Cooperative"
else
  puts "Skipped: Founding Starter Pack already exists"
end
