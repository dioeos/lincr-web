module RoomService
  module Services
    class ListRooms
      def initialize(room_repo:)
        @room_repo = room_repo
      end

      def call
        @room_repo.all
      rescue Errors::RedisError => e
        raise Errors::RoomListError, "Failed to list rooms: #{e.message}"
      end
    end
  end
end
