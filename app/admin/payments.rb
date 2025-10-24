ActiveAdmin.register Payment do
  permit_params :order_id, :user_id, :amount, :status, :transaction_id, :provider

  index do
    selectable_column
    id_column
    column :order
    column :user
    column :amount
    column :status
    column :transaction_id
    column :provider
    column :created_at
    actions
  end

  filter :order
  filter :user
  filter :status
  filter :amount
  filter :created_at

  form do |f|
    f.inputs do
      f.input :order
      f.input :user
      f.input :amount
      f.input :status, as: :select, collection: [0, 1] # pending/paid
      f.input :transaction_id
      f.input :provider
    end
    f.actions
  end
end
