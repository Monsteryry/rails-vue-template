require "test_helper"

class Api::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok with database version" do
    get api_health_url
    assert_response :success
    body = response.parsed_body
    assert_equal "ok", body["status"]
    assert_match(/PostgreSQL/, body["database"])
    assert_equal "PONG", body["redis"]
  end
end
