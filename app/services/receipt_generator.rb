# app/services/receipt_generator.rb
class ReceiptGenerator
  def initialize(order, downloaded_at = Time.current)
    @order = order
    @payment = order.payment
    @buyer = order.buyer
    @downloaded_at = downloaded_at
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 50) do |pdf|
      # === Header ===
      pdf.text "SHIPING RECEIPT", size: 22, style: :bold, align: :center, color: "333333"
      pdf.move_down 5
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      # === Order Info ===
      pdf.text "Receipt for Order ##{@order.id}", size: 16, style: :bold, color: "0070C0"
      pdf.move_down 10

      pdf.text "Date of Order: #{@order.created_at.strftime('%B %d, %Y %H:%M')}", size: 10
      pdf.text "Receipt Generated At: #{@downloaded_at.strftime('%B %d, %Y %H:%M')}", size: 10
      pdf.move_down 10

      # === Buyer & Seller ===
      pdf.text "Buyer Information", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      pdf.text "Name: #{@buyer.name}"
      pdf.text "Email: #{@buyer.email}"
      pdf.text "Delivery Address: #{@order.shipment&.address || '—'}"
      pdf.text "Recipient: #{@order.shipment&.first_name} #{@order.shipment&.last_name}"
      pdf.move_down 10

      pdf.text "Seller Information", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      pdf.text "Seller: #{@order.seller&.company_name.presence || @order.seller&.name.presence || 'Unknown Seller'}"
      pdf.move_down 15

      # === Payment Info ===
      pdf.text "Payment Details", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      pdf.text "Payment Method: #{@payment.provider.to_s.capitalize}"
      pdf.text "Payment Status: #{@payment.status.capitalize}"
      pdf.text "Transaction ID: #{@payment.transaction_id || '—'}"
      pdf.text "M-PESA Receipt #: #{@payment.mpesa_receipt_number || '—'}"
      pdf.move_down 10

      # === Order Items ===
      pdf.text "Order Summary", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5

      data = [["Product", "Quantity", "Price (KES)"]]
      @order.order_items.each do |item|
        data << [item.product.title, item.quantity.to_s, item.total_price.to_s]
      end

      pdf.table(data, header: true, width: 480) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        cells.padding = 6
        cells.border_color = 'DDDDDD'
      end

      pdf.move_down 10
      pdf.text "calculate_subtotal: ", style: :bold, size: 12
      pdf.text "KES #{@order.total}", size: 14, style: :bold, color: "008000"
      pdf.move_down 15

      # === Shipment Info (if available) ===
      if @order.shipment.present?
        pdf.text "Shipment Information", style: :bold, size: 12, color: "0070C0"
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.text "Status: #{@order.shipment.status.humanize}"
        pdf.text "Tracking Number: #{@order.shipment.tracking_number || '—'}"
        pdf.move_down 15
      end

      # === Footer ===
      pdf.move_down 30
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      pdf.text "Thank you for shopping with Shiping!", align: :center, style: :italic, size: 10, color: "555555"
      pdf.text "Need help? Contact support@yourdomain.com", align: :center, size: 9, color: "888888"
      pdf.move_down 5
      pdf.text "© #{Time.current.year} Shiping Marketplace", align: :center, size: 8, color: "AAAAAA"
    end.render
  end
end
