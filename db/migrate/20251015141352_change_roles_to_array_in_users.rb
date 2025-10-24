class ChangeRolesToArrayInUsers < ActiveRecord::Migration[7.0]
  def up
    # Drop the old text column and add a new array column
    remove_column :users, :roles
    add_column :users, :roles, :string, array: true, default: [], null: false
  end

  def down
    # Rollback to text column with YAML default
    remove_column :users, :roles
    add_column :users, :roles, :text, default: "--- []\n"
  end
end
