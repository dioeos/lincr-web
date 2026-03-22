require "roda"
require_relative "room_service/boot"

class App < Roda
  route do |r|
    r.on "api" do
      r.on "v1" do
        r.run RoomService::Routes::RoomRoutes
      end
    end
  end
end

