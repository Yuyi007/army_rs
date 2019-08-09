require 'test_helper'

class CdkeyControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
