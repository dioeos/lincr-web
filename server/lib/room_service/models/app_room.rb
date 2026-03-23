
module RoomService
  module Models
  AppRoom = Struct.new(
      :room_code,
      :janus_room_id,
      keyword_init: true
    ) do
      def to_h
        {
          room_code: room_code,
          janus_room_id: janus_room_id
        }
      end
    end
  end
end
