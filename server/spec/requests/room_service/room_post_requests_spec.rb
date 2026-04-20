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
    destroy_service.instance_variable_set(:@repo, @repo)
    end

    it "deletes the requested room" do
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
      expect(json).to eq(
        "message" => "Room ABC1234 deleted"
      )

      expect(fake_janus)
        .to have_received(:destroy_janus_room)
        .with(6767)
    end

    it "returns 404 on RoomNotFoundError" do
      post "/api/v1/rooms/delete/KOI1234"
      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json).to eq(
        "error" => "Room KOI1234 not found"
      )
    end
  end
end
