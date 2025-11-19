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
end
