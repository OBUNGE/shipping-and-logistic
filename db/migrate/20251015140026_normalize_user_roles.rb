class NormalizeUserRoles < ActiveRecord::Migration[7.0]
  def up
    # Ensure default is an empty array in YAML
    change_column_default :users, :roles, "--- []\n"

    # Backfill existing users
    User.reset_column_information
    User.find_each do |u|
      if u.roles.blank?
        u.update_columns(roles: YAML.dump([]))
      elsif u.roles.is_a?(String) && !u.roles.start_with?("---")
        # If it's a plain string like "buyer", wrap it in an array
        u.update_columns(roles: YAML.dump([u.roles]))
      end
    end
  end

  def down
    # Rollback just clears the default
    change_column_default :users, :roles, nil
  end
end
