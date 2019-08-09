require 'test_helper'

class GrantRecordsControllerTest < ActionController::TestCase
  setup do
    @grant_record = grant_records(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:grant_records)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create grant_record" do
    assert_difference('GrantRecord.count') do
      post :create, grant_record: { action: @grant_record.action, item_amount: @grant_record.item_amount, item_id: @grant_record.item_id, reason: @grant_record.reason, site_user_id: @grant_record.site_user_id, status: @grant_record.status, success: @grant_record.success, target_id: @grant_record.target_id, target_zone: @grant_record.target_zone }
    end

    assert_redirected_to grant_record_path(assigns(:grant_record))
  end

  test "should show grant_record" do
    get :show, id: @grant_record
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @grant_record
    assert_response :success
  end

  test "should update grant_record" do
    put :update, id: @grant_record, grant_record: { action: @grant_record.action, item_amount: @grant_record.item_amount, item_id: @grant_record.item_id, reason: @grant_record.reason, site_user_id: @grant_record.site_user_id, status: @grant_record.status, success: @grant_record.success, target_id: @grant_record.target_id, target_zone: @grant_record.target_zone }
    assert_redirected_to grant_record_path(assigns(:grant_record))
  end

  test "should destroy grant_record" do
    assert_difference('GrantRecord.count', -1) do
      delete :destroy, id: @grant_record
    end

    assert_redirected_to grant_records_path
  end
end
