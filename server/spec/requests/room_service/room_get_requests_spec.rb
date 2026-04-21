require "dotenv/load"
require_relative "../../spec_helper"

RSpec.describe "Get", type: :request do
  let(:redis) { Redis.new(url: ENV["REDIS_URL"])}

  before do
    redis.flushdb
  end
  describe "GET /rooms/list" do
    let(:repo) do
      RoomService::Repositories::RoomRepository.new
    end

    let(:list_service) do
      RoomService::Container
        .room_manager
        .instance_variable_get(:@list_rooms_service)
    end

    before do
      @original_room_repo = list_service.instance_variable_get(:@room_repo)
      list_service.instance_variable_set(:@room_repo, repo)
    end

    after do
      list_service.instance_variable_set(:@room_repo, @original_room_repo)
    end

    it "returns all rooms as JSON" do
      room = RoomService::Models::AppRoom.new(
        room_code: "ABC1234",
        janus_room_id: 1234
      )
      room2 = RoomService::Models::AppRoom.new(
        room_code: "KUD1234",
        janus_room_id: 5678
      )
      repo.save(room)
      repo.save(room2)
      get "/api/v1/rooms/list"
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json["rooms"]).to include(
        a_hash_including(
          "room_code" => "ABC1234",
          "janus_room_id" => 1234
        ),
        a_hash_including(
          "room_code" => "KUD1234",
          "janus_room_id" => 5678
        )
      )
      expect(json["rooms"].size).to eq(2)
    end

    it "returns empty JSON when no rooms exist" do
      get "/api/v1/rooms/list"
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json["rooms"]).to be_empty
    end

    it "returns 502 error on RoomListError due to RedisError rescue" do
      allow(repo)
        .to receive(:all)
        .and_raise(RoomService::Errors::RedisError, "Failed to find all rooms in repository")
      get "/api/v1/rooms/list"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to list rooms: Failed to find all rooms in repository")
    end
  end

  describe "GET /rooms/:room_code" do
    let(:repo) do
      RoomService::Repositories::RoomRepository.new
    end

    let(:get_service) do
      RoomService::Container
        .room_manager
        .instance_variable_get(:@get_room_service)
    end

    before do
      @original_room_repo = get_service.instance_variable_get(:@room_repo)
      get_service.instance_variable_set(:@room_repo, repo)
    end

    after do
      get_service.instance_variable_set(:@room_repo, @original_room_repo)
    end
    it "returns the requested room as JSON" do
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

    it "returns 422 Validation error for invalid request payload" do
      manager = RoomService::Routes::RoomRoutes.manager
      allow(manager).to receive(:get_room)
      get "/api/v1/rooms/KOM12"
      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body)
      expect(json["error"]["type"]).to eq("Validation Error")
      expect(json["error"]["fields"]).to include("room_code")
      expect(manager).not_to have_received(:get_room)
    end

    it "returns 502 RoomFindError due to RedisError rescue" do
      room = RoomService::Models::AppRoom.new(
          room_code: "HUG1234",
          janus_room_id: 8989
      )
      repo.save(room)
      allow(repo)
        .to receive(:find)
        .and_raise(RoomService::Errors::RedisError, "Failed to find room in repository")
      get "/api/v1/rooms/HUG1234"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to find room: Failed to find room in repository")
      expect(repo).to have_received(:find)
    end
  end
end
