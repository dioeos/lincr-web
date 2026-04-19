require "dotenv/load"
require "redis"

REDIS_URL = ENV["REDIS_URL"]
warn REDIS_URL

module RoomService
  module Repositories
    class RoomRepository
      def initialize(redis: Redis.new(url: REDIS_URL))
        @redis = redis
      end

      def save(room)
        # room_code -> janus_room_id
        @redis.hset("rooms", room.room_code, room.janus_room_id)
      end

      def find(room_code)
        id = @redis.hget("rooms", room_code)
        return nil unless id

        Models::AppRoom.new(
          room_code: room_code,
          janus_room_id: Integer(id, 10)
        )
      end

      def delete(room_code)
        @redis.hdel("rooms", room_code)
      end

      def all
        @redis.hgetall("rooms").map do |code, id|
          Models::AppRoom.new(
            room_code: code,
            janus_room_id: Integer(id, 10)
          )
        end
      end

      def exists?(room_code)
        @redis.hexists("rooms", room_code)
      end
    end
  end 
end
