require_relative "../../spec_helper"

RSpec.describe "Get", type: :request do
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
  end
end
