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
