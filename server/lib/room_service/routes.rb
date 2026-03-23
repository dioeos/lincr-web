module RoomService
  module Routes
    class RoomRoutes < Roda
      plugin :json
      ROOM_MANAGER = RoomService::Services::RoomManager.new
      route do |r|
        r.on "rooms" do
          r.get "hello" do
            { data: "hello" }
          end

          # POST /rooms/create
          r.post "create" do
            begin
              room_code = ROOM_MANAGER.create_room
              response.status = 201
              { room_code: room_code }
            rescue RoomService::Errors::RoomCreationError => e
              response.status = 502
              { error: e.message}
            end
          end
        end
      end
    end
  end
end
