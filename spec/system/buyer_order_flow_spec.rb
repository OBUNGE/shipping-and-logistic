require 'rails_helper'

RSpec.describe "Buyer Order Flow", type: :system do
  let!(:buyer) { create(:user, role: "buyer", email: "buyer@example.com", password: "password") }
  let!(:seller) { create(:user, role: "seller", email: "seller@example.com", password: "password") }
  let!(:product) { create(:product, seller: seller, title: "Test Product", price: 100, stock: 10) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  it "allows buyer to place and confirm an order" do
    # Buyer logs in
    visit new_user_session_path
    fill_in "Email", with: buyer.email
    fill_in "Password", with: "password"
    click_button "Log in"

    # Buyer places order
    visit product_path(product)
    click_button "Buy Now"

    expect(page).to have_content("Order placed")

    # Simulate STK push (mocked)
    order = Order.last
    visit order_path(order)
    click_button "Pay with Mpesa"

    expect(page).to have_content("STK push initiated")

    # Seller logs in and creates shipment
    click_link "Logout"
    visit new_user_session_path
    fill_in "Email", with: seller.email
    fill_in "Password", with: "password"
    click_button "Log in"

    visit order_path(order)
    click_button "Create Shipment"

    expect(page).to have_content("Shipment created")

    # Buyer logs back in and confirms delivery
    click_link "Logout"
    visit new_user_session_path
    fill_in "Email", with: buyer.email
    fill_in "Password", with: "password"
    click_button "Log in"

    visit order_path(order)
    click_button "Confirm Delivery"

    expect(page).to have_content("Order marked as delivered")
  end
end
