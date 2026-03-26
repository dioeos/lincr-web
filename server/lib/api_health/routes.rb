module ApiHealth
  module Routes
    class HealthRoutes < Roda
      plugin :json

      route do |r|
        r.get "check" do
          response.status = 200
          { status: "healthy" }
        end
      end
    end
  end
end
