module RoomService
  module Routes
    class RoomRoutes < Roda
      route do |r|
        r.get "hello" do
          "hello!" 
        end
      end
    end
  end
end
