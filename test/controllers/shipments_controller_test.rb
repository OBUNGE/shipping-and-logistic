require "test_helper"

class ShipmentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shipments_index_url
    assert_response :success
  end

  test "should get show" do
    get shipments_show_url
    assert_response :success
  end

  test "should get create" do
    get shipments_create_url
    assert_response :success
  end
end
