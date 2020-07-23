require 'test_helper'

class SignControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get sign_create_url
    assert_response :success
  end

end
