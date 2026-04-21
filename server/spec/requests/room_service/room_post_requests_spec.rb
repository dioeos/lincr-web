require "dotenv/load"
require_relative "../../spec_helper"

RSpec.describe "Post", type: :request do
  let(:redis) { Redis.new(url: ENV["REDIS_URL"])}
  
  before do
    redis.flushdb
  end
  describe "POST /rooms/create" do
    let(:fake_janus) do
      instance_double(RoomService::Clients::JanusClient)
    end

    let(:repo) do
      RoomService::Repositories::RoomRepository.new
    end

    let(:create_service) do
      RoomService::Container
        .room_manager
        .instance_variable_get(:@create_room_service)
    end

    before do
      @original_janus_client = create_service.instance_variable_get(:@janus_client)
      @original_room_repo = create_service.instance_variable_get(:@room_repo)
      create_service.instance_variable_set(:@janus_client, fake_janus)
      create_service.instance_variable_set(:@room_repo, repo)
    end

    after do
      create_service.instance_variable_set(:@janus_client, @original_janus_client)
      create_service.instance_variable_set(:@room_repo, @original_room_repo)
    end


    it "returns successful create JSON on valid request" do
      allow(fake_janus)
        .to receive(:create_janus_room)
        .and_return(4646)

      post "/api/v1/rooms/create"
      expect(last_response.status).to eq(201)
      json = JSON.parse(last_response.body)
      expect(json["room_code"]).not_to be_empty
      expect(json["janus_room_id"]).to eq(4646)
      expect(fake_janus).to have_received(:create_janus_room)
    end

    it "returns 502 on RoomCreationError due to JanusError rescue" do
      allow(fake_janus)
        .to receive(:create_janus_room)
        .and_raise(RoomService::Errors::JanusError, "Failed to create Janus room")
      post "/api/v1/rooms/create"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to create room: Failed to create Janus room")
      expect(fake_janus).to have_received(:create_janus_room)
    end

    it "returns 502 on RoomCreationError due to RedisError rescue" do
      allow(fake_janus)
        .to receive(:create_janus_room)
        .and_return(5050)

      allow(repo)
        .to receive(:save)
        .and_raise(RoomService::Errors::RedisError, "Failed to save room in repository")
      post "/api/v1/rooms/create"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to create room: Failed to save room in repository")
      expect(fake_janus).to have_received(:create_janus_room)
      expect(repo).to have_received(:save)
    end
      
  end

  describe "POST /rooms/delete/:room_code" do
    let(:fake_janus) do
      instance_double(RoomService::Clients::JanusClient)
    end

    let(:repo) do
      RoomService::Repositories::RoomRepository.new
    end

    let(:destroy_service) do
      RoomService::Container
        .room_manager
        .instance_variable_get(:@destroy_room_service)
    end
    
    before do
      @original_janus_client = destroy_service.instance_variable_get(:@janus_client)
      @original_room_repo = destroy_service.instance_variable_get(:@room_repo)

      destroy_service.instance_variable_set(:@janus_client, fake_janus)
      destroy_service.instance_variable_set(:@room_repo, repo)
    end

    after do
      destroy_service.instance_variable_set(:@janus_client, @original_janus_client)
      destroy_service.instance_variable_set(:@room_repo, @original_room_repo)
    end

    it "returns successful delete JSON on valid request" do
      room = RoomService::Models::AppRoom.new(
        room_code: "ABC1234",
        janus_room_id: 6767
      )
      repo.save(room)

      allow(fake_janus)
        .to receive(:destroy_janus_room)
        .with(6767)
        .and_return(nil)

      post "/api/v1/rooms/delete/ABC1234"
      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json["message"]).to eq("Room ABC1234 deleted")

      expect(fake_janus)
        .to have_received(:destroy_janus_room)
        .with(6767)
    end

    it "returns 404 on RoomNotFoundError rescue" do
      post "/api/v1/rooms/delete/KOI1234"
      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Room KOI1234 not found")
    end

    it "returns 502 on RoomDeletionError due to JanusError rescue" do
      room = RoomService::Models::AppRoom.new(
        room_code: "KUJ1234",
        janus_room_id: 9090
      )
      repo.save(room)
      allow(fake_janus)
        .to receive(:destroy_janus_room)
        .with(9090)
        .and_raise(RoomService::Errors::JanusError, "Failed to destroy Janus room")

      post "/api/v1/rooms/delete/KUJ1234"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to delete room: Failed to destroy Janus room")
    end

    it "returns 502 on RoomDeletionError due to RedisError rescue" do
      room = RoomService::Models::AppRoom.new(
        room_code: "KOL1234",
        janus_room_id: 0101
      )
      repo.save(room)
      allow(fake_janus)
        .to receive(:destroy_janus_room)
        .with(0101)
        .and_return(nil)
      allow(repo)
        .to receive(:delete)
        .with(room.room_code)
        .and_raise(RoomService::Errors::RedisError, "Failed to remove from redis")

      post "/api/v1/rooms/delete/KOL1234"
      expect(last_response.status).to eq(502)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Failed to delete room: Failed to remove from redis")
    end


    it "returns validation error JSON on invalid request payload" do
      manager = RoomService::Routes::RoomRoutes.manager
      allow(manager).to receive(:destroy_room)
      post "/api/v1/rooms/delete/SHORT"
      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body)
      expect(json["error"]["type"]).to eq("Validation Error")
      expect(json["error"]["fields"]).to include("room_code")
      expect(manager).not_to have_received(:destroy_room)
    end
  end
end
