module RoomService
  module Services
    class ListRooms
      def initialize(room_repo:)
        @room_repo = room_repo
      end

      def call
        @room_repo.all
      end
    end
  end
end
