module RoomService
  module Services
    class DestroyRoom
      def initialize(room_repo:, janus_client:)
        @room_repo = room_repo
        @janus_client = janus_client
      end

      def call(room_code)
        room = @room_repo.find_by_code(room_code)

        raise Errors::RoomNotFoundError, "Room #{room_code} not found" if room.nil?

        @janus_client.destroy_janus_room(room.janus_room_id)
        @room_repo.delete(room_code)
      end
    end
  end
end
