class AddMessageToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :message, :string
  end
end
