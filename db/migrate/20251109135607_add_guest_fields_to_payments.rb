class AddGuestFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :guest_email, :string
    add_column :payments, :guest_phone, :string
  end
end
