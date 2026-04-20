describe RoomService::Services::DestroyRoom do
  let(:fake_janus) do
    instance_double(RoomService::Clients::JanusClient)
  end

  let(:fake_repo) do
    instance_double(RoomService::Repositories::RoomRepository)
  end

  let(:service) do
    described_class.new(
      room_repo: fake_repo,
      janus_client: fake_janus,
    )
  end

  let(:room_code) { "ABC1234"}
  let(:room) do
    instance_double(
      RoomService::Models::AppRoom,
      room_code: room_code,
      janus_room_id: 1234567
    )
  end

  describe "#call" do
    it "destroys the Janus room and deletes the room from the repo" do
      allow(fake_repo).to receive(:find).with(room_code).and_return(room)
      allow(fake_janus).to receive(:destroy_janus_room).with(1234567).and_return(true)
      allow(fake_repo).to receive(:delete).with(room_code)
      service.call(room_code)
      expect(fake_repo).to have_received(:find).with(room_code)
      expect(fake_janus).to have_received(:destroy_janus_room).with(1234567)
      expect(fake_repo).to have_received(:delete).with(room_code)
    end

    it "raises RoomNotFoundError when the room does not exist" do
      allow(fake_repo).to receive(:find).with(room_code).and_raise(RoomService::Errors::RoomNotFoundError, "Room not Found")
      allow(fake_janus).to receive(:destroy_janus_room)
      expect do
        service.call(room_code)
      end.to raise_error(RoomService::Errors::RoomNotFoundError, "Room not Found")
      expect(fake_janus).not_to have_received(:destroy_janus_room)
    end

    it 'does not delete the room from the repo if Janus destroy fails' do
      allow(fake_repo).to receive(:find).with(room_code).and_return(room)
      allow(fake_janus).to receive(:destroy_janus_room).with(1234567).and_raise(RoomService::Errors::JanusError, "Janus destroy failed")
      allow(fake_repo).to receive(:delete)
      expect do
        service.call(room_code)
      end.to raise_error(RoomService::Errors::RoomDeletionError, "Failed to delete room: Janus destroy failed")
      expect(fake_repo).not_to have_received(:delete)
    end
  end
end
