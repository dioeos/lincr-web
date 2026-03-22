module RoomService
  module Services
    class RoomManager
      def initialize(janus: RoomService::Clients::JanusClient.new)
        @janus_client = janus
        @active_rooms = {}
      end

      def get_room(room_code)
        @active_rooms.key?(room_code)
      end

      def create_room
        code = generate_room_code(7)
        janus_room_id = @janus_client.create_janus_room

        room = RoomService::Models::AppRoom.new(
          room_code: code,
          janus_room_id: janus_room_id
        )

        @active_rooms[code] = room
        warn "Created room successfully"
        code
      rescue RoomService::Errors::JanusError => e
        warn "Failed to create room"
        raise RoomService::Errors::RoomCreationError, "Failed to create room: #{e.message}"
      end

      def join_room(room_code)
        @active_rooms[room_code]
      end

      def generate_room_code(length = 7)
        alphabet = ("A".."Z").to_a + ("0".."9").to_a
        loop do
          code = Array.new(length) do
            alphabet[SecureRandom.random_number(alphabet.length)]
          end.join
          return code unless @active_rooms.key?(code)
        end
      end
    end
  end
end
