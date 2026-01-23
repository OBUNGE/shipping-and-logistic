class AddPricingFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :cost_price, :decimal, precision: 10, scale: 2, comment: "What you paid for the product"
    add_column :products, :profit_margin_percent, :decimal, precision: 5, scale: 2, comment: "Target profit margin %"
    add_column :products, :price_ending, :string, comment: "Psychological pricing ending (99, 95, 90, 00)"
  end
end
