require_relative "../../spec_helper"

RSpec.describe "Post", type: :request do
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
