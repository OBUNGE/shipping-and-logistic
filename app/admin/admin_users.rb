ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form html: { class: "admin-stk-form" } do |f|
    div class: "admin-stk-panel" do
      f.inputs do
        f.input :email
        f.input :password
        f.input :password_confirmation
      end
    end
    div class: "admin-stk-panel" do
      f.actions do
        f.action :submit, label: "Save Admin User", button_html: { class: "admin-stk-button" }
      end
    end
    para "Enter credentials carefully", class: "admin-stk-hint"
  end
end
