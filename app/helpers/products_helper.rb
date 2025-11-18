module ProductsHelper
  # Builds a form builder for a nested variant so we can render the partial
  def form_builder_for(variant)
    # Create a dummy form builder for Product, then nest into variants
    product = variant.product || Product.new
    form_builder = ActionView::Helpers::FormBuilder.new(
      :product,
      product,
      self,
      {}
    )

    form_builder.fields_for(:variants, variant) do |vf|
      return vf
    end
  end
end
