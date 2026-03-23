module RoomService
  module Container
    module_function

    def room_repo
      @room_repo ||= Repositories::RoomRepository.new
    end

    def janus_client
      @janus_client ||= Clients::JanusClient.new
    end

    def code_generator
      @code_generator ||= Utilities::CodeGenerator.new
    end

    def create_room_service
      @create_room_service ||= Services::CreateRoom.new(
        room_repo: room_repo,
        janus_client: janus_client,
        code_generator: code_generator
      )
    end

    def destroy_room_service
      @destroy_room_service ||= Services::DestroyRoom.new(
        room_repo: room_repo,
        janus_client: janus_client
      )
    end

    def list_rooms_service
      @list_rooms_service ||= Services::ListRooms.new(
        room_repo: room_repo,
      )
    end

    def room_manager
      @room_manager ||= Managers::RoomManager.new(
        create_room_service: create_room_service,
        destroy_room_service: destroy_room_service,
        list_rooms_service: list_rooms_service
      )
    end
  end
end

