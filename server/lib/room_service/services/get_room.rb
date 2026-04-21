module RoomService
  module Services
    class GetRoom
      def initialize(room_repo:)
        @room_repo = room_repo
      end

      def call(room_code)
        room = @room_repo.find(room_code)
      raise Errors::RoomNotFoundError, "Room #{room_code} not found" if room.nil?
        room
      rescue Errors::RedisError => e
        raise Errors::RoomFindError, "Failed to find room: #{e.message}"
        room
      end
    end
  end
end
