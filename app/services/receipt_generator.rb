# 📄 File: app/services/receipt_generator.rb
require 'prawn/table'
require 'open-uri'
require 'rqrcode'
require 'chunky_png'

class ReceiptGenerator
  include ActionView::Helpers::NumberHelper # for number_to_currency

  def initialize(order, downloaded_at = Time.current)
    @order = order
    @payment = order.payment
    @buyer = order.buyer
    @downloaded_at = downloaded_at
    @currency = determine_currency
    @exchange_rate = 130.0
    @logo_url = "https://yourdomain.com/assets/afrixpress-logo.png" # ✅ Replace with your actual logo URL
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 50) do |pdf|
      # === Company Logo ===
      begin
        logo_io = URI.open(@logo_url)
        pdf.image logo_io, width: 100, position: :center
        pdf.move_down 10
      rescue
        # silently skip if logo fails
      end

      # === QR Code ===
      begin
        qr = RQRCode::QRCode.new("Order ##{@order.id} - #{@payment.transaction_id}")
        png = qr.as_png(size: 120)
        pdf.image StringIO.new(png.to_s), position: :center
        pdf.move_down 10
      rescue
        # silently skip if QR fails
      end

      # === Header ===
      pdf.text "AfriXpress RECEIPT", size: 22, style: :bold, align: :center, color: "333333"
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

      data = [["Product", "Quantity", "Price (#{@currency})"]]
      @order.order_items.each do |item|
        price = item.subtotal
        discounted = if item.product.discount.present? && item.product.discount.percentage.to_f > 0
          price * (1 - item.product.discount.percentage / 100.0)
        else
          nil
        end

        price_display = if discounted
          "#{format_price(price)} → #{format_price(discounted)}"
        else
          format_price(price)
        end

        data << [item.product.title, item.quantity.to_s, price_display]
      end

      pdf.table(data, header: true, width: 480) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
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
        pdf.text "Status: #{@order.shipment.status.humanize}"
        pdf.text "Tracking Number: #{@order.shipment.tracking_number || '—'}"
        pdf.move_down 15
      end

      # === Footer ===
      pdf.move_down 30
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      pdf.text "Thank you for shopping with AfriXpress!", align: :center, style: :italic, size: 10, color: "555555"
      pdf.text "Need help? Contact support@afrixpress.com", align: :center, size: 9, color: "888888"
      pdf.move_down 5
      pdf.text "© #{Time.current.year} AfriXpress Marketplace", align: :center, size: 8, color: "AAAAAA"
    end.render
  end

  private

  def determine_currency
    method = @payment.provider.to_s.downcase
    case method
    when "mpesa", "paystack" then "KES"
    when "paypal" then "USD"
    else "KES"
    end
  end

  def format_price(amount)
    if @currency == "KES"
      number_to_currency(amount * @exchange_rate, unit: "KES ")
    else
      number_to_currency(amount, unit: "$")
    end
  end
end
