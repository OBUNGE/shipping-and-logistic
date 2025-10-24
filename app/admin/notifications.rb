# app/admin/notifications.rb
ActiveAdmin.register Notification do
  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :user
    column :message
    column :read
    column :created_at
    actions
  end

  filter :user
  filter :read
  filter :created_at
end
