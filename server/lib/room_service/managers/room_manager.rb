module RoomService
  module Managers
    class RoomManager
      def initialize(
        create_room_service:,
        destroy_room_service:,
        list_rooms_service:
      )
        @create_room_service = create_room_service
        @destroy_room_service = destroy_room_service
        @list_rooms_service = list_rooms_service
      end

      def create_room
        @create_room_service.call
      end

      def destroy_room(room_code)
        @destroy_room_service.call(room_code)
      end

      def list_rooms
        @list_rooms_service.cal
      end
    end
  end
end
