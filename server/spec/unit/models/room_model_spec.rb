describe RoomService::Models::AppRoom do
  it "creates room struct on valid attributes" do
    room = described_class.new(
      room_code: "ABC1234",
      janus_room_id: 1234567
    )
    expect(room.room_code).to eq("ABC1234")
    expect(room.janus_room_id).to eq(1234567)
  end

  it "rejects room struct on invalid room code length" do
    expect do
      described_class.new(
        room_code: "ABC",
        janus_room_id: 1234567
      )
    end.to raise_error(Dry::Struct::Error)
  end
  
  it "rejects room struct on invalid room code type" do
    expect do
      described_class.new(
        room_code: 1290,
        janus_room_id: 1234567
      )
    end.to raise_error(Dry::Struct::Error)
  end

  it "rejects room struct on invalid janus_room_id type" do
    expect do
      described_class.new(
        room_code: "ABC1234",
        janus_room_id: "1234567"
      )
    end.to raise_error(Dry::Struct::Error)
  end

  it "rejects missing room_code" do
    expect do
      described_class.new(
        janus_room_id: 1234567
      )
    end.to raise_error(Dry::Struct::Error)
  end

  it "rejects missing janus_room_id" do
    expect do
      described_class.new(
        room_code: "ABC1234"
      )
    end.to raise_error(Dry::Struct::Error)
  end

  it "rejects extra attributes" do
    expect do
      described_class.new(
        room_code: "ABC1234",
        janus_room_id: 1234567,
        unexpected: "value"
      )
    end.to raise_error(Dry::Struct::Error)
  end
end
