require "test_helper"

class MpesaPaymentsControllerTest < ActionDispatch::IntegrationTest
  test "should get stk_push" do
    get mpesa_payments_stk_push_url
    assert_response :success
  end

  test "should get callback" do
    get mpesa_payments_callback_url
    assert_response :success
  end
end
