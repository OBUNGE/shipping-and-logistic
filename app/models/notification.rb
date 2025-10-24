# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user

  validates :message, presence: true
  def self.ransackable_attributes(auth_object = nil)
    %w[id message read created_at updated_at user_id]
  end

  # Allow only safe associations to be searchable
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end
