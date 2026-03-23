module RoomService
  module Managers
    class RoomManager
      def initialize(
        create_room_service:,
        get_room_service:,
        destroy_room_service:,
        list_rooms_service:
      )
        @create_room_service = create_room_service
        @get_room_service = get_room_service
        @destroy_room_service = destroy_room_service
        @list_rooms_service = list_rooms_service
      end

      def create_room
        @create_room_service.call
      end

      def get_room(room_code)
        @get_room_service.call(room_code)
      end

      def destroy_room(room_code)
        @destroy_room_service.call(room_code)
      end

      def list_rooms
        @list_rooms_service.call
      end
    end
  end
end
