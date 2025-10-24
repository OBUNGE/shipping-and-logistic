require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get buyer" do
    get dashboards_buyer_url
    assert_response :success
  end

  test "should get seller" do
    get dashboards_seller_url
    assert_response :success
  end
end
