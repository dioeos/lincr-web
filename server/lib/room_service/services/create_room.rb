module RoomService
  module Services
    class CreateRoom
      def initialize(room_repo:, janus_client:, code_generator:)
        @room_repo = room_repo
        @janus_client = janus_client
        @code_generator = code_generator
      end

      def call
        code = generate_unique_room_code
        janus_room_id = @janus_client.create_janus_room

        room = Models::AppRoom.new(
            room_code: code,
            janus_room_id: janus_room_id
        )
        @room_repo.save(room)
        room
      rescue Errors::JanusError => e
        raise Errors::RoomCreationError, "Failed to create room: #{e.message}"
      rescue Errors::RedisError => e
        raise Errors::RoomCreationError, "Failed to create room: #{e.message}"
      end

      private

      def generate_unique_room_code
        loop do
          code = @code_generator.call
        return code unless @room_repo.exists?(code)
        end
      end
    end
  end
end
