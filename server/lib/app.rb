require "roda"
require_relative "api_health/boot"
require_relative "room_service/boot"

class App < Roda
  route do |r|
    r.on "api" do
      r.on "v1" do
        r.on "rooms" do
          r.run RoomService::Routes::RoomRoutes
        end
        r.on "health" do
          r.run ApiHealth::Routes::HealthRoutes
        end
      end
    end
  end
end

