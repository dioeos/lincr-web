require "dotenv/load"
require_relative "../../spec_helper"

RSpec.describe "Get", type: :request do
  let(:redis) { Redis.new(url: ENV["REDIS_URL"])}

  before do
    redis.flushdb
  end

  describe "GET /rooms/list" do
    it "returns all rooms as JSON" do
      repo = RoomService::Repositories::RoomRepository.new
      room = RoomService::Models::AppRoom.new(
        room_code: "ABC1234",
        janus_room_id: 1234
      )
      repo.save(room)
      get "/api/v1/rooms/list"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json["rooms"]).to include(
        a_hash_including(
          "room_code" => "ABC1234",
          "janus_room_id" => 1234
        )
      )
    end

    it "returns empty JSON when no rooms exist" do
      get "/api/v1/rooms/list"
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json["rooms"]).to be_empty
    end
  end

  describe "GET /rooms/:room_code" do
    it "returns the requested room as JSON" do
      repo = RoomService::Repositories::RoomRepository.new
      room = RoomService::Models::AppRoom.new(
          room_code: "BCD1234",
          janus_room_id: 6789
      )
      repo.save(room)
      get "/api/v1/rooms/BCD1234"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json).to eq(
        {
          "room_code" => "BCD1234",
          "janus_room_id" => 6789
        }
      )
    end

    it "returns 404 error on non-existing room" do
      get "/api/v1/rooms/BCK1234"
      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json).to eq(
        "error" => "Room BCK1234 not found"
      )
    end
  end
end
