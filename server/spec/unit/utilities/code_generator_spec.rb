describe RoomService::Utilities::CodeGenerator do
  it "generates room code of correct length" do
    code_generator = described_class.new
    code = code_generator.call
    expect(code.length).to eq(7)
    expect(code).to match(/[A-Z0-9]{7}/)
  end
end
