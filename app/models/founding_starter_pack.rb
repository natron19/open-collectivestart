class FoundingStarterPack < ApplicationRecord
  belongs_to :working_community
  has_one :user, through: :working_community

  validates :working_community_id, presence: true, uniqueness: true
end
