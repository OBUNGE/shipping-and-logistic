class Review < ApplicationRecord
  belongs_to :product
  belongs_to :user
  has_many :votes
  has_many :reports


  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true

  # Optional: ensure helpful_count is always an integer
attribute :helpful_count, :integer, default: 0

end
