describe RoomService::Services::GetRoom do
  let(:fake_repo) do
    instance_double(RoomService::Repositories::RoomRepository)
  end

  let(:service) do
    described_class.new(
      room_repo: fake_repo
    )
  end

  let(:room_code) {"ABC1234"}
  let(:room) do
    instance_double(
      RoomService::Models::AppRoom,
      room_code: room_code,
      janus_room_id: 1234567
    )
  end

  describe "#call" do
    it "finds the app room with room code and returns the room object" do
      allow(fake_repo).to receive(:find).with(room_code).and_return(room)
      res = service.call(room_code)
      expect(fake_repo).to have_received(:find).with(room_code)
      expect(res).to eq(room)
    end

    it "raises RoomNotFoundError when the room does not exist" do
      allow(fake_repo).to receive(:find).with(room_code).and_raise(RoomService::Errors::RoomNotFoundError, "Room not Found")
      expect do
        service.call(room_code)
      end.to raise_error(RoomService::Errors::RoomNotFoundError, "Room not Found")
      expect(fake_repo).to have_received(:find)
    end
  end
end
