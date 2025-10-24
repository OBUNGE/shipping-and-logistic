FactoryBot.define do
  factory :report do
    user { nil }
    review { nil }
    reason { "MyString" }
  end
end
