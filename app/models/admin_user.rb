class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :validatable

def self.ransackable_attributes(auth_object = nil)
    # Only allow safe fields to be searchable
    %w[id email created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    [] # no associations searchable by default
  end

end
