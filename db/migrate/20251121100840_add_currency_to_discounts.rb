class AddCurrencyToDiscounts < ActiveRecord::Migration[8.0]
  def change
    add_column :discounts, :currency, :string
  end
end
