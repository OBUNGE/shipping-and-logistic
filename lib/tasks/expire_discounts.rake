# lib/tasks/expire_discounts.rake
namespace :discounts do
  task expire: :environment do
    Discount.where("expires_at < ?", Time.current).update_all(active: false)
    puts "✅ Expired discounts deactivated"
  end
end
