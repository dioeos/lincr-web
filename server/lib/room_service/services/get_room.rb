module RoomService
  module Services
    class GetRoom
      def initialize(room_repo:)
        @room_repo = room_repo
      end

      def call(room_code)
        room = @room_repo.find_by_code(room_code)
      raise Errors::RoomNotFoundError, "Room #{room_code} not found" if room.nil?
        room
      end
    end
  end
end
