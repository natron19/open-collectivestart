require "rails_helper"

RSpec.describe "WorkingCommunities", type: :request do
  let(:user)       { create(:user) }
  let(:other)      { create(:user) }
  let!(:community) { create(:working_community, user: user) }

  # ── Unauthenticated access ───────────────────────────────────────────────────

  it "redirects unauthenticated user from index" do
    get working_communities_path
    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects unauthenticated user from show" do
    get working_community_path(community)
    expect(response).to redirect_to(sign_in_path)
  end

  # ── Index ────────────────────────────────────────────────────────────────────

  it "returns 200 for a signed-in user" do
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

  # ── New ──────────────────────────────────────────────────────────────────────

  it "returns 200 for the new form" do
    sign_in_as(user)
    get new_working_community_path
    expect(response).to have_http_status(:ok)
  end

  # ── Create ───────────────────────────────────────────────────────────────────

  it "creates a community with valid params and redirects to show" do
    sign_in_as(user)
    expect {
      post working_communities_path, params: { working_community: attributes_for(:working_community) }
    }.to change(WorkingCommunity, :count).by(1)
    expect(response).to redirect_to(working_community_path(user.working_communities.order(created_at: :desc).first))
  end

  it "re-renders new with 422 on invalid params" do
    sign_in_as(user)
    post working_communities_path, params: { working_community: { name: "x" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  # ── Show ─────────────────────────────────────────────────────────────────────

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

  # ── Edit ─────────────────────────────────────────────────────────────────────

  it "returns 200 on edit for the owner" do
    sign_in_as(user)
    get edit_working_community_path(community)
    expect(response).to have_http_status(:ok)
  end

  it "returns 404 on edit for a non-owner" do
    sign_in_as(other)
    get edit_working_community_path(community)
    expect(response).to have_http_status(:not_found)
  end

  # ── Update ───────────────────────────────────────────────────────────────────

  it "updates the community and redirects to show for the owner" do
    sign_in_as(user)
    patch working_community_path(community), params: { working_community: { name: "Updated Name" } }
    expect(response).to redirect_to(working_community_path(community))
    expect(community.reload.name).to eq("Updated Name")
  end

  it "returns 404 on update for a non-owner" do
    sign_in_as(other)
    patch working_community_path(community), params: { working_community: { name: "Hijacked" } }
    expect(response).to have_http_status(:not_found)
  end

  # ── Destroy ──────────────────────────────────────────────────────────────────

  it "deletes the community and redirects for the owner" do
    sign_in_as(user)
    expect {
      delete working_community_path(community)
    }.to change(WorkingCommunity, :count).by(-1)
    expect(response).to redirect_to(working_communities_path)
  end

  it "returns 404 on destroy for a non-owner" do
    sign_in_as(other)
    expect {
      delete working_community_path(community)
    }.not_to change(WorkingCommunity, :count)
    expect(response).to have_http_status(:not_found)
  end
end
