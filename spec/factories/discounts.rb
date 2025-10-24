FactoryBot.define do
  factory :discount do
    product { nil }
    percentage { 1 }
    active { false }
    expires_at { "2025-10-17 10:48:12" }
  end
end
