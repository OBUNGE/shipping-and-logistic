class Shipment < ApplicationRecord
  # === Associations ===
  belongs_to :order
  has_many :shipment_status_logs, dependent: :destroy

  # Through order, we can access buyer and seller (users)
  delegate :buyer, :seller, to: :order

  # === Carrier options ===
  enum :carrier, {
    dhl:   "dhl",
    sendy: "sendy"
    # Add more carriers later (e.g., :ups, :fedex, :g4s)
  }

  # === Status lifecycle ===
  enum :status, {
    pending:    "pending",
    created:    "created",
    in_transit: "in_transit",
    delivered:  "delivered",
    cancelled:  "cancelled",
    failed:     "failed"
  }

  # === Validations ===
  validates :status, presence: true
  validates :carrier, presence: true
  validates :tracking_number, presence: true, uniqueness: true
  validates :first_name, :last_name, :address, presence: true

  # ✅ Fix for Formtastic error: use greater_than_or_equal_to
  validates :cost, numericality: { greater_than_or_equal_to: 0.01 }, allow_nil: true

  # === Callbacks ===
  after_initialize :set_default_status, if: :new_record?
  after_update :handle_status_change, if: :saved_change_to_status?

  # === Public methods to update status ===
  def mark_as_created!
    update!(status: :created)
  end

  def mark_as_shipped!
    update!(status: :in_transit)
  end

  def mark_as_delivered!
    update!(status: :delivered)
  end

  def cancel!
    update!(status: :cancelled)
  end

  def fail!
    update!(status: :failed)
  end

  # === Ransack (Admin filtering) ===
  def self.ransackable_attributes(auth_object = nil)
    %w[id order_id carrier tracking_number cost status created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order]
  end

  # === Estimated delivery (optional)
  def estimated_delivery_date
    created_at&.+(5.days)
  end

  private

  # Set default status when new shipment is initialized
  def set_default_status
    self.status ||= "pending"
  end

  # ✅ Consolidated callback for status changes
  def handle_status_change
    log_status_change
    notify_users
    send_status_email
  end

  # Log every status change to ShipmentStatusLog
  def log_status_change
    shipment_status_logs.create!(
      status: status,
      changed_by_id: Current.user&.id || order.seller_id,
      changed_at: Time.current
    )
  end

  # Notify buyer and seller via in-app notifications
  def notify_users
    [buyer, seller].each do |user|
      Notification.create!(
        user: user,
        message: "Order ##{order.id} shipment status updated to #{status.humanize}"
      )
    end
  end

  # ✅ Safe email alert to buyer on status change
  def send_status_email
    return unless buyer&.email.present?
    ShipmentMailer.status_update(self, status).deliver_later
  end
end
