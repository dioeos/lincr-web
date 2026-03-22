
module RoomService
  module Models
  AppRoom = Struct.new(
      :room_code,
      :janus_room_id,
      keyword_init: true
    )
  end
end
