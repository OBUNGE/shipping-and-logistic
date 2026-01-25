module ProductsHelper
  # Builds a nested form builder for either a Variant or a VariantImage
  def form_builder_for(record)
    product =
      if record.is_a?(VariantImage)
        record.variant&.product || Product.new
      elsif record.is_a?(Variant)
        record.product || Product.new
      else
        Product.new
      end

    form_with(model: product, local: true) do |form|
      if record.is_a?(Variant)
        form.fields_for(:variants, record) { |vf| return vf }
      elsif record.is_a?(VariantImage)
        form.fields_for(:variants, record.variant) do |vf|
          vf.fields_for(:variant_images, record) { |image_fields| return image_fields }
        end
      end
    end
  end

  # Renders markdown-style formatting in product descriptions
  # Converts **text** to bold and - items to bullet points
  def render_description_markdown(text)
    return "No description provided." if text.blank?

    # Convert **text** to <strong>text</strong>
    formatted = text.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')

    # Convert lines starting with - to list items
    lines = formatted.split("\n")
    result = []
    in_list = false

    lines.each do |line|
      if line.strip.start_with?("-")
        result << "<ul>" unless in_list
        in_list = true
        # Remove leading dash and whitespace
        list_item = line.strip.sub(/^-\s*/, "")
        result << "<li>#{list_item}</li>"
      else
        if in_list && line.strip.present?
          result << "</ul>"
          in_list = false
        end
        result << line if line.strip.present?
      end
    end

    result << "</ul>" if in_list

    result.join("\n").html_safe
  end
end
