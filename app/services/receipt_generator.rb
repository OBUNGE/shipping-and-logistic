# app/services/receipt_generator.rb
class ReceiptGenerator
  def initialize(order, downloaded_at = Time.current)
    @order = order
    @payment = order.payment
    @buyer = order.buyer
    @downloaded_at = downloaded_at
  end

  def generate
  Prawn::Document.new do |pdf|
    pdf.text "Receipt for Order ##{@order.id}", size: 20, style: :bold
    pdf.move_down 10

    pdf.text "Date of Order: #{@order.created_at.strftime('%B %d, %Y %H:%M')}"
    pdf.text "Receipt Downloaded At: #{@downloaded_at.strftime('%B %d, %Y %H:%M')}"
    pdf.text "Buyer: #{@buyer.name} (#{@buyer.email})"
    pdf.text "Delivery Address: #{@order.shipment&.address || '—'}"
    pdf.text "Recipient: #{@order.shipment&.first_name} #{@order.shipment&.last_name}"
    pdf.text "Seller: #{@order.seller&.company_name.presence || @order.seller&.name.presence || 'Unknown Seller'}"
    pdf.text "Payment Status: #{@payment.status.capitalize}"
    pdf.text "Payment Method: #{@payment.provider}"
    pdf.text "M-PESA Receipt #: #{@payment.mpesa_receipt_number}"
    pdf.text "Transaction ID: #{@payment.transaction_id}"
    pdf.text "Total Amount: KES #{@order.total}"

    pdf.move_down 20
    pdf.text "Products:", style: :bold
    @order.order_items.each do |item|
      pdf.text "- #{item.product.title} x#{item.quantity}"
    end

    if @order.shipment.present?
      pdf.move_down 10
      pdf.text "Shipment Status: #{@order.shipment.status.humanize}"
      pdf.text "Tracking #: #{@order.shipment.tracking_number}"
    end

    pdf.move_down 30
    pdf.text "Thank you for shopping with Shiping!", align: :center, style: :italic
    pdf.text "For support, contact us at support@yourdomain.com", align: :center, size: 10
  end.render
end

end
