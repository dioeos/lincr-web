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
        begin
          @redis.hset("rooms", room.room_code, room.janus_room_id)
        rescue Redis::BaseError => e
          raise Errors::RedisError, "Failed to save room in repository: #{e.message}"
        end
      end

      def find(room_code)
        begin
          id = @redis.hget("rooms", room_code)
        rescue Redis::BaseError => e
          raise Errors::RedisError, "Failed to find room in repository: #{e.message}"
        end

        return nil unless id

        Models::AppRoom.new(
          room_code: room_code,
          janus_room_id: Integer(id, 10)
        )
      end

      def delete(room_code)
        begin
          @redis.hdel("rooms", room_code)
        rescue Redis::BaseError => e
          raise Errors::RedisError, "Failed to delete room from repository: #{e.message}"
        end
      end

      def all
        begin
          @redis.hgetall("rooms").map do |code, id|
            Models::AppRoom.new(
              room_code: code,
              janus_room_id: Integer(id, 10)
            )
          end
        rescue Redis::BaseError => e
          raise Errors::RedisError, "Failed to list all rooms from repository: #{e.message}"
        end
      end

      def exists?(room_code)
        @redis.hexists("rooms", room_code)
      end
    end
  end 
end
