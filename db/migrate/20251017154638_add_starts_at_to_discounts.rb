class AddStartsAtToDiscounts < ActiveRecord::Migration[8.0]
  def change
    add_column :discounts, :starts_at, :date
  end
end
