require "dry-struct"

module Types
  include Dry.Types()
end

module RoomService
  module Models
    class AppRoom < Dry::Struct
      schema schema.strict
      attribute :room_code, Types::Strict::String.constrained(size: 7)
      attribute :janus_room_id, Types::Strict::Integer

      def to_h
        {
          room_code: room_code,
          janus_room_id: janus_room_id
        }
      end
    end
  end
end
