describe RoomService::Clients::JanusClient do
  subject(:client) do
    described_class.new(
      base_url: "http://janus.test/janus",
      api_secret: "secret123"
    )
  end

  let(:internet) { instance_double(Async::HTTP::Internet) }
  let(:response) { instance_double("Async::HTTP::Protocol::Response") }

  before do
    allow(client).to receive(:internet).and_return(internet)
  end
  
  describe "#post" do
    it "posts JSON and returns parsed data" do
      payload = {
        "janus" => "create",
        "transaction" => "abc"
      }

      allow(internet).to receive(:post).and_return(response)
      allow(response).to receive(:status)
        .and_return(200)

      allow(response).to receive(:read).and_return(
        { "janus" => "success", "data" => { "id" => 123 } }.to_json
      )
      allow(response).to receive(:close)
      result = client.post("http://janus.test/janus", payload)

      expect(internet).to have_received(:post).with(
        "http://janus.test/janus",
        hash_including("content-type" => "application/json"),
        payload.to_json
      )

      expect(result).to eq(
        "janus" => "success",
        "data" => { "id" => 123 }
)
      expect(response).to have_received(:close)
    end

    it "raises JanusError when HTTP POST status is not successful" do
      payload = {
        "janus" => "create",
        "transaction" => "abc"
      }
      allow(internet).to receive(:post).and_return(response)
      allow(response).to receive(:status)
        .and_return(500)
      allow(response).to receive(:close)
      expect {
        client.post("http://janus.test/janus", payload)
      }.to raise_error(RoomService::Errors::JanusError, "HTTP error: 500")
      expect(response).to have_received(:close)
end

    it "raises JanusError when returned response has janus => error" do
      payload = {
        "janus" => "create",
        "transaction" => "abc"
      }
      allow(internet).to receive(:post).and_return(response)
      allow(response).to receive(:status)
        .and_return(200)
      allow(response).to receive(:read).and_return(
        {
          "janus" => "error",
          "error" => {
            "code" => 403,
            "reason" => "Unauthorized"
          }
        }.to_json
      )
      allow(response).to receive(:close)

      expect {
        client.post("http://janus.test/janus", payload)
      }.to raise_error(RoomService::Errors::JanusError, "Janus error: 403 Unauthorized")
    end
  end

  describe "#get" do
    it "returns parsed JSON for a successful response" do
      
      allow(internet).to receive(:get)
        .with("http://janus.test/janus/info")
        .and_return(response)

      allow(response).to receive(:status)
        .and_return(200)

      allow(response).to receive(:read).and_return(
        {
          "janus" => "server_info",
          "name" => "Janus"
        }.to_json
      )
      allow(response).to receive(:close)
      result = client.get("http://janus.test/janus/info")
      expect(result).to eq(
        "janus" => "server_info",
        "name" => "Janus"
      )
      expect(response).to have_received(:close)
    end

    it "raises JanusError when HTTP GET status is not successful" do
      allow(internet).to receive(:get)
        .with("http://janus.test/janus/info")
        .and_return(response)

      allow(response).to receive(:status)
        .and_return(500)
      allow(response).to receive(:close)

      expect {
        client.get("http://janus.test/janus/info")
      }.to raise_error(RoomService::Errors::JanusError, "HTTP error: 500")

      expect(response).to have_received(:close)
    end


    it "raises JanusError when returned response has janus => error" do
      allow(internet).to receive(:get)
        .with("http://janus.test/janus/info")
        .and_return(response)
      allow(response).to receive(:status)
        .and_return(200)
      allow(response).to receive(:read).and_return(
        {
          "janus" => "error",
          "error" => {
            "code" => 403,
            "reason" => "Unauthorized"
          }
        }.to_json
      )
      allow(response).to receive(:close)

      expect {
        client.get("http://janus.test/janus/info")
      }.to raise_error(RoomService::Errors::JanusError, "Janus error: 403 Unauthorized")
    end
  end

  describe "#create_janus_session" do
    it "posts create-session request and returns session id" do
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "data" => { "id" => 42}
      )
      result = client.create_janus_session
      expect(client).to have_received(:post).with(
        "http://janus.test/janus",
        {
          "janus" => "create",
          "transaction" => "tx123",
          "apisecret" => "secret123"
        }
      )
      expect(result).to eq(42)
    end
  end

  describe "#attach_plugin_handle" do
    it "posts attach request and returns handle id" do
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "data" => { "id" => 77 }
      )

      result = client.attach_plugin_handle(42, "janus.plugin.videoroom")

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42",
        {
          "janus" => "attach",
          "plugin" => "janus.plugin.videoroom",
          "transaction" => "tx123",
          "apisecret" => "secret123"
        }
      )
      expect(result).to eq(77)
    end
  end

  describe "#destroy_janus_session" do
    it "posts destroy-session request and returns nil" do
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "janus" => "success"
      )

      result = client.destroy_janus_session(42)

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42",
        {
          "janus" => "destroy",
          "transaction" => "tx123",
          "apisecret" => "secret123"
        }
      )
      expect(result).to be_nil
    end
  end

  describe "#get_janus_room" do
    it "posts exists request and destroys the session afterward" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "plugindata" => {
          "data" => {
            "exists" => true
          }
        }
      )
      allow(client).to receive(:destroy_janus_session)

      result = client.get_janus_room(1234)

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42/77",
        {
          "janus" => "message",
          "transaction" => "tx123",
          "apisecret" => "secret123",
          "body" => {
            "request" => "exists",
            "room" => 1234
          }
        }
      )
      expect(result).to eq(
        "plugindata" => {
          "data" => {
            "exists" => true
          }
        }
      )
      expect(client).to have_received(:destroy_janus_session).with(42)
    end

    it "destroys the session when the request raises" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_raise(RoomService::Errors::JanusError, "boom")
      allow(client).to receive(:destroy_janus_session)

      expect {
        client.get_janus_room(1234)
      }.to raise_error(RoomService::Errors::JanusError, "boom")

      expect(client).to have_received(:destroy_janus_session).with(42)
    end
  end

  describe "#create_janus_room" do
    it "creates a Janus room and destroys the session afterward" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_janus_room_id).and_return(1234)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "janus" => "success"
      )
      allow(client).to receive(:destroy_janus_session)

      result = client.create_janus_room

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42/77",
        {
          "janus" => "message",
          "transaction" => "tx123",
          "apisecret" => "secret123",
          "body" => {
            "request" => "create",
            "room" => 1234
          }
        }
      )
      expect(result).to eq(1234)
      expect(client).to have_received(:destroy_janus_session).with(42)
    end

    it "destroys the session when room creation raises" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_janus_room_id).and_return(1234)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_raise(RoomService::Errors::JanusError, "boom")
      allow(client).to receive(:destroy_janus_session)

      expect {
        client.create_janus_room
      }.to raise_error(RoomService::Errors::JanusError, "boom")

      expect(client).to have_received(:destroy_janus_session).with(42)
    end
  end

  describe "#list_janus_rooms" do
    it "returns the Janus room list" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "plugindata" => {
          "data" => {
            "list" => [
              { "room" => 1234 },
              { "room" => 5678 }
            ]
          }
        }
      )
      allow(client).to receive(:destroy_janus_session)

      result = client.list_janus_rooms

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42/77",
        {
          janus: "message",
          body: {
            request: "list"
          },
          transaction: "tx123",
          apisecret: "secret123"
        }
      )
      expect(result).to eq(
        [
          { "room" => 1234 },
          { "room" => 5678 }
        ]
      )
      expect(client).to have_received(:destroy_janus_session).with(42)
    end

    it "returns an empty array when Janus omits the list" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "plugindata" => {
          "data" => {}
        }
      )
      allow(client).to receive(:destroy_janus_session)

      result = client.list_janus_rooms

      expect(result).to eq([])
      expect(client).to have_received(:destroy_janus_session).with(42)
    end
  end

  describe "#destroy_janus_room" do
    it "posts destroy-room request and destroys the session afterward" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "janus" => "success"
      )
      allow(client).to receive(:destroy_janus_session)

      result = client.destroy_janus_room(1234, permanent: true)

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42/77",
        {
          janus: "message",
          body: {
            request: "destroy",
            room: 1234,
            permanent: true
          },
          transaction: "tx123",
          apisecret: "secret123"
        }
      )
      expect(result).to eq(
        "janus" => "success"
      )
      expect(client).to have_received(:destroy_janus_session).with(42)
    end

    it "uses permanent false by default" do
      allow(client).to receive(:create_janus_session).and_return(42)
      allow(client).to receive(:attach_plugin_handle)
        .with(42, "janus.plugin.videoroom")
        .and_return(77)
      allow(client).to receive(:generate_tx_id).and_return("tx123")
      allow(client).to receive(:post).and_return(
        "janus" => "success"
      )
      allow(client).to receive(:destroy_janus_session)

      client.destroy_janus_room(1234)

      expect(client).to have_received(:post).with(
        "http://janus.test/janus/42/77",
        {
          janus: "message",
          body: {
            request: "destroy",
            room: 1234,
            permanent: false
          },
          transaction: "tx123",
          apisecret: "secret123"
        }
      )
      expect(client).to have_received(:destroy_janus_session).with(42)
    end
  end
end
