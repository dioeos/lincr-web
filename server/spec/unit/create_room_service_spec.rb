describe RoomService::Services::CreateRoom do
  let(:fake_janus) do
    instance_double(RoomService::Clients::JanusClient)
  end

  let(:fake_repo) do
    instance_double(RoomService::Repositories::RoomRepository)
  end

  let(:fake_cg) do
    instance_double(RoomService::Utilities::CodeGenerator)
  end

  let(:service) do
    described_class.new(
      room_repo: fake_repo,
      janus_client: fake_janus,
      code_generator: fake_cg
    )
  end

  describe "#call" do
    it "creates and saves a room" do
      allow(fake_cg).to receive(:call).and_return("ABC1234")
      allow(fake_repo).to receive(:save)
      allow(fake_repo).to receive(:exists?).with("ABC1234").and_return(false)
      allow(fake_janus).to receive(:create_janus_room).and_return(12345)

      room = service.call

      expect(room.room_code).to eq("ABC1234")
      expect(room.janus_room_id).to eq(12345)
      expect(fake_repo).to have_received(:save).with(room)
    end

    it "retries when a generated code already exists" do
      allow(fake_cg).to receive(:call).and_return("TAKEN1", "FREE22")
      allow(fake_repo).to receive(:exists?).with("TAKEN1").and_return(true)
      allow(fake_repo).to receive(:exists?).with("FREE22").and_return(false)
      allow(fake_janus).to receive(:create_janus_room).and_return(12345)
      allow(fake_repo).to receive(:save)

      room = service.call

      expect(room.room_code).to eq("FREE22")
      expect(room.janus_room_id).to eq(12345)
      expect(fake_cg).to have_received(:call).twice
      expect(fake_repo).to have_received(:exists?).with("TAKEN1")
      expect(fake_repo).to have_received(:exists?).with("FREE22")
      expect(fake_repo).to have_received(:save).with(room)
    end

    it 'raises RoomCreationError when Janus fails to create room' do
      allow(fake_cg).to receive(:call).and_return("ABC1234")
      allow(fake_repo).to receive(:exists?).with("ABC1234").and_return(false)
      allow(fake_repo).to receive(:save)
      allow(fake_janus).to receive(:create_janus_room).and_raise(RoomService::Errors::JanusError, "Janus failed")
      expect { service.call }.to raise_error(RoomService::Errors::RoomCreationError, "Failed to create room: Janus failed")
      expect(fake_repo).not_to have_received(:save)
    end
  end

end
