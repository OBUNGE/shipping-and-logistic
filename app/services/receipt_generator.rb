require 'prawn/table'
require 'open-uri'
require 'rqrcode'
require 'chunky_png'

class ReceiptGenerator
  include ActionView::Helpers::NumberHelper # for number_to_currency

  def initialize(order, payment = nil, downloaded_at = Time.current)
    @order = order
    @payment = payment || order.payments.last
    @buyer = order.buyer
    @downloaded_at = downloaded_at
    @currency = "KES" # ✅ always KES now
    @logo_url = "https://yourdomain.com/assets/afrixpress-logo.png"
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 50) do |pdf|
      # === Company Logo ===
      begin
        logo_io = URI.open(@logo_url)
        pdf.image logo_io, width: 100, position: :center
        pdf.move_down 10
      rescue => e
        Rails.logger.warn("Logo load failed: #{e.message}")
      end

      # === QR Code ===
      if @payment&.transaction_id.present?
        begin
          qr = RQRCode::QRCode.new("Order ##{@order.id} - #{@payment.transaction_id}")
          png = qr.as_png(size: 120)
          pdf.image StringIO.new(png.to_s), position: :center
          pdf.move_down 10
        rescue => e
          Rails.logger.warn("QR code generation failed: #{e.message}")
        end
      end

      # === Header ===
      pdf.text "Tajaone RECEIPT", size: 22, style: :bold, align: :center, color: "333333"
      pdf.move_down 5
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      # === Order Info ===
      pdf.text "Receipt for Order ##{@order.id}", size: 16, style: :bold, color: "0070C0"
      pdf.move_down 10
      pdf.text "Date of Order: #{@order.created_at.strftime('%d %B %Y, %I:%M %p')}", size: 10
      pdf.text "Receipt Generated At: #{@downloaded_at.strftime('%d %B %Y, %I:%M %p')}", size: 10
      pdf.move_down 10

      # === Buyer & Seller ===
      pdf.text "Buyer Information", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      buyer_name = safe_buyer_name(@buyer)
      pdf.text "Name: #{buyer_name}"
      pdf.text "Email: #{@buyer&.email || '—'}"
      pdf.move_down 10

      pdf.text "Seller Information", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      seller_display = @order.seller&.company_name.presence || @order.seller&.name.presence || "Unknown Seller"
      pdf.text "Seller: #{seller_display}"
      pdf.move_down 15

      # === Payment Info ===
      pdf.text "Payment Details", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5

      if @payment.present?
        pdf.text "Payment Method: #{@payment.provider.to_s.capitalize}"
        pdf.text "Payment Status: #{@payment.status.to_s.capitalize}"
        pdf.text "Transaction ID: #{@payment.transaction_id || '—'}"
        pdf.text "M-PESA Receipt #: #{@payment.mpesa_receipt_number || '—'}"
        pdf.text "Amount Paid: #{format_price(@payment.amount)}"
      else
        pdf.text "No payment record found."
      end

      pdf.move_down 10

      # === Order Items ===
      pdf.text "Order Summary", style: :bold, size: 12, color: "0070C0"
      pdf.stroke_horizontal_rule
      pdf.move_down 5

      data = [["Product", "Quantity", "Price (#{@currency})"]]
      @order.order_items.each do |item|
        product_title = item.product&.title || "Unknown Product"
        price = item.subtotal || 0
        discounted = if item.product&.discount&.percentage.to_f > 0
                       price * (1 - item.product.discount.percentage / 100.0)
                     end

        price_display = discounted ? "#{format_price(price)} → #{format_price(discounted)}" : format_price(price)

        # ✅ Combine variants safely
        variant_info =
          if item.respond_to?(:variants) && item.variants.present?
            item.variants.map { |v| "#{v.name}: #{v.value}" }.join(", ")
          elsif item.variant.present?
            "#{item.variant.name}: #{item.variant.value}"
          else
            "—"
          end

        product_display = variant_info == "—" ? product_title : "#{product_title} (#{variant_info})"

        data << [product_display, item.quantity.to_s, price_display]
      end

      pdf.table(data, header: true, width: 480) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        columns(1..2).align = :right
        cells.padding = 6
        cells.border_color = 'DDDDDD'
      end

      pdf.move_down 10
      pdf.text "Total Amount:", style: :bold, size: 12
      pdf.text format_price(@order.total), size: 14, style: :bold, color: "008000"
      pdf.move_down 15

      # === Shipment Info ===
      if @order.shipment.present?
        pdf.text "Shipment Information", style: :bold, size: 12, color: "0070C0"
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.text "Status: #{@order.shipment.status.to_s.humanize}"
        pdf.text "Tracking Number: #{@order.shipment.tracking_number || '—'}"
        pdf.move_down 15
      end

      # === Footer ===
      pdf.move_down 30
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      pdf.text "Thank you for shopping with Tajaone!", align: :center, style: :italic, size: 10, color: "555555"
      pdf.text "Need help? Contact sales@Tajaone.app", align: :center, size: 9, color: "888888"
      pdf.move_down 5
      pdf.text "© #{Time.current.year} Tajaone", align: :center, size: 8, color: "AAAAAA"
    end.render
  end

  private

  def format_price(amount)
    return "—" unless amount.present?
    number_to_currency(amount, unit: "KES ")
  end

  def safe_buyer_name(buyer)
    return "—" unless buyer.present?
    buyer.name.presence ||
      [buyer.first_name, buyer.last_name].compact.join(" ").presence ||
      buyer.email.presence ||
      "Unknown Buyer"
  end
end
