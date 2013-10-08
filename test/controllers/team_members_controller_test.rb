require 'test_helper'

class TeamMembersControllerTest < ActionController::TestCase
  test "should get rescue" do
    get :rescue
    assert_response :success
  end

end
