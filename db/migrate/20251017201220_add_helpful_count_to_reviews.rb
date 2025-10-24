class AddHelpfulCountToReviews < ActiveRecord::Migration[8.0]
  def change
  add_column :reviews, :helpful_count, :integer, default: 0
end

end
