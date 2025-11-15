class ChangeOrderCurrencyDefaultToKes < ActiveRecord::Migration[8.0]
def change
    change_column_default :orders, :currency, from: "USD", to: "KES"
  end
end