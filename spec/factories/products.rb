# spec/factories/products.rb
FactoryBot.define do
  factory :product do
    title { "Test Product" }
    description { "A great product for testing." }
    price { 100 }
    stock { 10 } # ✅ Add this line
    seller { association :user, role: "seller" }
  end
end
