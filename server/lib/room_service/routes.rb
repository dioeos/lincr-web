module RoomService
  module Routes
    class RoomRoutes < Roda
      plugin :json
      manager = Container.room_manager

      route do |r|
        r.on "rooms" do
          r.get "hello" do
            { data: "hello" }
          end

          # POST /rooms/create
          r.post "create" do
            room = manager.create_room
            response.status = 201
            {
              room_code: room.room_code,
              janus_room_id: room.janus_room_id
            }
          rescue Errors::RoomCreationError => e
            response.status = 502
            { error: e.message}
          end
        end
      end
    end
  end
end
