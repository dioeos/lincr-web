module RoomService
  module Errors
    class JanusError < StandardError; end
    class RoomCreationError < StandardError; end
    class RoomNotFoundError < StandardError; end
    class RedisError < StandardError; end
    class RoomDeletionError < StandardError; end
    class RoomListError < StandardError; end
    class RoomFindError < StandardError; end
  end
end
