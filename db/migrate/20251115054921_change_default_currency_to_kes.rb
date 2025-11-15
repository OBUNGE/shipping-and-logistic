class ChangeDefaultCurrencyToKes < ActiveRecord::Migration[8.0]
   def change
    # Payments table
    change_column_default :payments, :currency, from: "USD", to: "KES"

    # Orders table
    change_column_default :orders, :currency, from: "USD", to: "KES"

    # Products table
    change_column_default :products, :currency, from: "USD", to: "KES"
  end
end
