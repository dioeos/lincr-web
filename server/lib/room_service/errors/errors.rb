module RoomService
  module Errors
    class JanusError < StandardError; end
    class RoomCreationError < StandardError; end
    class RoomNotFoundError < StandardError; end
  end
end
