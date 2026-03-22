require "roda"

class App < Roda
  route do |r|
    r.get "hello" do
      "hello!"
    end
  end
end
