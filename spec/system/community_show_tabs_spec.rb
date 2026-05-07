require "rails_helper"

RSpec.describe "Community show page — tabs", type: :system, js: true do
  let(:user)      { create(:user) }
  let(:community) { create(:working_community, :with_pack, user: user) }

  before do
    visit sign_in_path
    fill_in "Email",    with: user.email
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
      expect(page).to have_content("Likely Shared Values")
    end
  end

  it "switches to the Business Model Canvas tab and shows content" do
    click_button "Business Model Canvas"
    expect(page).to have_css("#pane-canvas.active", wait: 5)
    within("#pane-canvas") do
      expect(page).to have_content("Customer Segments")
    end
  end

  it "updates the URL with a ?tab= parameter on tab switch" do
    click_button "Business Model Canvas"
    expect(page).to have_current_path(/tab=business_model_canvas/)
  end

  it "activates the correct tab when loaded with a ?tab= param" do
    visit working_community_path(community, tab: "legal_form_comparison")
    expect(page).to have_css("#tab-legal.active", wait: 5)
  end

  it "reveals the raw response via the collapse toggle" do
    click_link "Show raw response"
    expect(page).to have_css("#raw-response.show", wait: 5)
    expect(page).to have_content("ARTIFACT 1")
  end

  it "keeps the lawyer-review alert visible on every tab" do
    expect(page).to have_css(".lawyer-review-banner")
    click_button "Business Model Canvas"
    expect(page).to have_css(".lawyer-review-banner")
    click_button "Legal Form Comparison"
    expect(page).to have_css(".lawyer-review-banner")
  end
end
