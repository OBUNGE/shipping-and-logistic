class Shipment < ApplicationRecord
  # === Associations ===
  belongs_to :order
  has_many :shipment_status_logs, dependent: :destroy

  delegate :buyer, :seller, to: :order

  # === Carrier options ===
  # Ensure `carrier` column is a string in your DB migration
  enum :carrier, {
    dhl:       "dhl",
    sendy:     "sendy",
    ena_coach: "ena_coach",
    g4s:       "g4s",
    fargo:     "fargo"
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
  validates :status, :carrier, :tracking_number, presence: true
  validates :tracking_number, uniqueness: true

  # Require shipping details only on creation, not on every update
  validates :first_name, :last_name, :phone_number, :country, :city, :address,
            presence: true, on: :create

  # Allow blank cost values, but enforce numeric if present
  validates :cost,
            numericality: { greater_than_or_equal_to: 0.01 },
            allow_nil: true,
            allow_blank: true

  # === Callbacks ===
  after_update :handle_status_change, if: :saved_change_to_status?

  # === Public methods ===
  def mark_as_created!;   update!(status: :created);   end
  def mark_as_shipped!;   update!(status: :in_transit); end
  def mark_as_delivered!; update!(status: :delivered); end
  def cancel!;            update!(status: :cancelled); end
  def fail!;              update!(status: :failed);    end

  # === Ransack (Admin filtering) ===
  def self.ransackable_attributes(auth_object = nil)
    %w[
      id order_id carrier tracking_number cost status created_at updated_at
      first_name last_name phone_number address city county country region delivery_notes
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order shipment_status_logs]
  end

  # === Estimated delivery (optional)
  def estimated_delivery_date
    created_at&.+(5.days)
  end

  private

  def handle_status_change
    log_status_change
    notify_users
    send_status_email
  end

  def log_status_change
    shipment_status_logs.create!(
      status: status,
      changed_by_id: Current.user&.id || order.seller_id,
      changed_at: Time.current
    )
  end

  def notify_users
    return unless defined?(Notification)
    [buyer, seller].each do |user|
      Notification.create!(
        user: user,
        message: "Order ##{order.id} shipment status updated to #{status.humanize}"
      )
    end
  end

  def send_status_email
    return unless buyer&.email.present? && defined?(ShipmentMailer)
    ShipmentMailer.status_update(self, status).deliver_later
  end
end
