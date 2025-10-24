FactoryBot.define do
  factory :variant do
    product { nil }
    name { "MyString" }
    value { "MyString" }
    price_modifier { "9.99" }
  end
end
