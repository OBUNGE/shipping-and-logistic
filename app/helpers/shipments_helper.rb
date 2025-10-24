module ShipmentsHelper
  # 🔹 Progress percentage for visual bar
  def shipment_progress(status)
    case status.to_s
    when "pending"     then 25
    when "in_transit"  then 50
    when "delivered"   then 100
    when "cancelled"   then 0
    else 10
    end
  end

  # 🔹 Progress bar color
  def progress_color(status)
    case status.to_s
    when "pending"     then "orange"
    when "in_transit"  then "blue"
    when "delivered"   then "green"
    when "cancelled"   then "red"
    else "gray"
    end
  end

  # 🔹 Status icon (FontAwesome or Bootstrap icons)
  def status_icon(status)
    case status.to_s
    when "pending"
      "<i class='fas fa-clock text-warning'></i>".html_safe
    when "in_transit"
      "<i class='fas fa-truck-moving text-primary'></i>".html_safe
    when "delivered"
      "<i class='fas fa-check-circle text-success'></i>".html_safe
    when "cancelled"
      "<i class='fas fa-times-circle text-danger'></i>".html_safe
    else
      "<i class='fas fa-question-circle text-muted'></i>".html_safe
    end
  end

  # 🔹 Estimated delivery date (5 days from shipment creation)
  def estimated_delivery(shipment)
    return nil unless shipment.created_at.present?
    (shipment.created_at + 5.days).strftime("%B %d, %Y")
  end
end
