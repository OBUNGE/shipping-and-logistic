class ChangeVariantIdNullableInOrderItems < ActiveRecord::Migration[8.0]
  def change
        change_column_null :order_items, :variant_id, true
  end
end
