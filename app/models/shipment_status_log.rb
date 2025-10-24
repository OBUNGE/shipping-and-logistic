class ShipmentStatusLog < ApplicationRecord
  # === Associations ===
  belongs_to :shipment
  belongs_to :changed_by, class_name: "User"

  # === Validations ===
  validates :status, presence: true
  validates :changed_by, presence: true
  validates :changed_at, presence: true

  # === Callbacks ===
  before_validation :set_changed_at, on: :create

  # === Scopes ===
  scope :recent, -> { order(changed_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  # === Ransack (Admin filtering) ===
  def self.ransackable_attributes(auth_object = nil)
    %w[id shipment_id status changed_by_id changed_at created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[shipment changed_by]
  end

  # === Instance Methods ===
  def human_status
    status.to_s.humanize
  end

  private

  def set_changed_at
    self.changed_at ||= Time.current
  end
end
