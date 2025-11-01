# app/helpers/categories_helper.rb
module CategoriesHelper
  def category_icon(name)
    {
      "Industrial & Construction" => "🏗️",
      "Agriculture & Farming"     => "🚜",
      "Office & Business"         => "💼",
      "Electronics & Energy"      => "🔌",
      "Home & Living"             => "🏠"
    }[name] || "📦"
  end
end
