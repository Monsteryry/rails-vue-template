# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/health" do
  before { get api_health_path }

  it "returns ok" do
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("ok")
  end

  it "reports PostgreSQL and Redis" do
    expect(response.parsed_body).to include(
      "database" => a_string_including("PostgreSQL"),
      "redis" => "PONG"
    )
  end
end
