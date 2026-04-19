describe RoomService::Services::ListRooms do
  let(:fake_repo) do
    instance_double(RoomService::Repositories::RoomRepository)
  end

  let(:room_code1) {"ABC1234"}
  let(:room_code2) {"XYZ1234"}

  let(:room1) do
    instance_double(
      RoomService::Models::AppRoom,
      room_code: room_code1,
      janus_room_id: 1234567
    )
  end

  let(:room2) do
    instance_double(
      RoomService::Models::AppRoom,
      room_code: room_code1,
      janus_room_id: 3456789
    )
  end
  
  let(:service) do
    described_class.new(
      room_repo: fake_repo
    )
  end

  describe "#call" do
    it "lists all the rooms in the room repository" do
      allow(fake_repo).to receive(:all).and_return([room1, room2])
      res = service.call
      expect(fake_repo).to have_received(:all)
      expect(res).to eq([room1, room2])
    end
  end
end
