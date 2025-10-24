class AddRolesToUsers < ActiveRecord::Migration[8.0]
 def change
    add_column :users, :roles, :text, default: [].to_yaml
  end
end