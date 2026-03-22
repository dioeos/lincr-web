# Custom error when dealing with Janus API

module RoomService
  module Errors
    class JanusError < StandardError
    end
  end
end
