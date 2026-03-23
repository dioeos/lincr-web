module RoomService
  module Utilities
    class CodeGenerator
      DEFAULT_LENGTH = 7

      def call(length = DEFAULT_LENGTH)
        alphabet = ("A".."Z").to_a + ("0".."9").to_a
        Array.new(length) {alphabet.sample}.join
      end
    end
  end
end
