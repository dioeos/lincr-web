module RoomService
  module Routes
    class RoomRoutes < Roda
      plugin :json

      class << self
        attr_writer :manager

        def manager
          @manager ||= Container.room_manager
        end
      end

      route do |r|
        # POST /rooms/create
        r.post "create" do
          room = self.class.manager.create_room
          response.status = 201
          {
            room_code: room.room_code,
            janus_room_id: room.janus_room_id
          }
        rescue Errors::RoomCreationError => e
          response.status = 502
          { error: e.message}
        end

        # POST /rooms/delete/:room_code
        r.post "delete", String do |room_code|
          result = RoomService::Validation::RoomCodeSchema.call(room_code: room_code)

          unless result.success?
            r.response.status = 422
            next({
              error: {
                type: "Validation Error",
                fields: result.errors.to_h
              }
            })
          end

          self.class.manager.destroy_room(room_code)
          response.status = 200
          {
            message: "Room #{room_code} deleted"
          }
        rescue Errors::RoomNotFoundError => e
          r.response.status = 404
          { error: e.message }
        rescue Errors::RoomDeletionError => e
          r.responsestatus = 502
          { error: e.message }
        end

        # GET /rooms/list
        r.get "list" do
          rooms = self.class.manager.list_rooms
          response.status = 200
          { rooms: rooms.map(&:to_h) }
        end

        r.on String do |room_code|
          # GET /rooms/:room_code
          r.get true do
            room = self.class.manager.get_room(room_code)
            room.to_h
          rescue Errors::RoomNotFoundError => e
            r.response.status = 404
            { error: e.message }
          end
        end
      end
    end
  end
end
