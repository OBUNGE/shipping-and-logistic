class AddCurrencyToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :currency, :string, default: "USD", null: false

  end
end
