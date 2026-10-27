# frozen_string_literal: true

require "test_helper"

class Api::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok" do
    get api_health_url

    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end

  test "reports PostgreSQL and Redis" do
    get api_health_url

    assert_match(/PostgreSQL/, response.parsed_body["database"])
    assert_equal "PONG", response.parsed_body["redis"]
  end
end
