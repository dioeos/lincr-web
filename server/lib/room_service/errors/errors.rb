module RoomService
  module Errors
    class JanusError < StandardError; end
    class RoomCreationError < StandardError; end
    class RoomNotFoundError < StandardError; end
    class RedisError < StandardError; end
    class RoomDeletionError < StandardError; end
  end
end
