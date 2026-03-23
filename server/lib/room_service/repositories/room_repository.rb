module RoomService
  module Repositories
    class RoomRepository
      def initialize
        @rooms = {}
      end

      def save(room)
        @rooms[room.room_code] = room
      end

      def find_by_code(room_code)
        @rooms[room_code]
      end

      def delete(room)
        @rooms.delete(room_code)
      end

      def all
        @rooms.values
      end

      def exists?(room_code)
        @rooms.key?(room_code)
      end
    end
  end 
end
