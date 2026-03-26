# Integration tests that test health of HTTP requests to Falcon server and Roda app

require_relative "../spec_helper"

RSpec.describe "Health check" do
  it "returns ok" do
    get "/api/v1/health/check"
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["status"]).to eq("healthy")
  end
end
