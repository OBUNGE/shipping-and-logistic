# spec/system/order_flow_spec.rb
require 'rails_helper'

RSpec.describe "Order Flow", type: :system do
  it "shows homepage" do
    visit root_path
    expect(page).to have_content("Welcome")
  end
end
