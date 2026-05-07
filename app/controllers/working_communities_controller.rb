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
