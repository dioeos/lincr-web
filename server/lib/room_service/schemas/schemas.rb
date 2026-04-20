require "dry-schema"

module RoomService
  module Validation
    RoomCodeSchema = Dry::Schema.Params do
      required(:room_code).filled(:string, size?: 7)
    end
  end
end
