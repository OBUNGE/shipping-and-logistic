class AddActiveRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :active_role, :string, default: "buyer"
  end
end