require "dotenv/load"
require "securerandom"
require "json"
require "async/http/internet"

JANUS_HTTP_URL = ENV["JANUS_HTTP_URL"]
JANUS_API_SECRET  = ENV["JANUS_API_SECRET"]

module RoomService
  module Clients
    class JanusClient
      def initialize(
        base_url: ENV.fetch("JANUS_HTTP_URL", "").chomp("/"),
        api_secret: ENV.fetch("JANUS_API_SECRET", "")
      )
        warn "Base URL: #{base_url}"
        @base_url = base_url
        @api_secret = api_secret
        @internet = nil
      end

      def generate_tx_id(length = 12)
        SecureRandom.alphanumeric(length)
      end

      def internet
        @internet ||= Async::HTTP::Internet.new
      end

      def has_janus_error?(data)
        return [false, ""] unless data["janus"] == "error"

        error = data["error"] || {}
        [true, "Janus error: #{error["code"]} #{error["reason"]}"]
      end

      def post(url, payload)
        headers = {
          "content-type" => "application/json"
        }
        body = JSON.dump(payload)
        resp = internet.post(url, headers, body)

        unless (200..299).include?(resp.status)
          raise RoomService::Errors::JanusError, "HTTP error: #{resp.status}"
        end

        data = JSON.parse(resp.read)
        has_error, error_msg = has_janus_error?(data)
        raise RoomService::Errors::JanusError, error_msg if has_error
        data

      ensure
        resp&.close
      end

      def get(url)
        resp = internet.get(url)
        unless resp.status.success?
          raise RoomService::Errors::JanusError, "HTTP error: #{resp.status}"
        end

        data = JSON.parse(resp.read)
        has_error, error_msg = has_janus_error?(data)
        raise RoomService::Errors::JanusError, error_msg if has_error
        data
      ensure
        resp&.close
      end

      def create_janus_session
        tx_id = generate_tx_id
        payload = {
          "janus" => "create",
          "transaction" => tx_id,
          "apisecret" => @api_secret
        }
        data = post(@base_url, payload)
        data.fetch("data").fetch("id")
      end

      def get_janus_instance
        get("#{@base_url}/info")
      end

      def attach_plugin_handle(session_id, plugin_id)
        tx_id = generate_tx_id
        payload = {
          "janus" => "attach",
          "plugin" => plugin_id,
          "transaction" => tx_id,
          "apisecret" => @api_secret
        }
        data = post("#{@base_url}/#{session_id}", payload)
        data.fetch("data").fetch("id")
      end

      def destroy_janus_session(session_id)
        payload = {
          "janus" => "destroy",
          "transaction" => generate_tx_id,
          "apisecret" => @api_secret
        }

        post("#{@base_url}/#{session_id}", payload)
        nil
      end

      def get_janus_room(room_id)
        session_id = create_janus_session

        begin
          plugin_handle = attach_plugin_handle(session_id, "janus.plugin.videoroom")

          payload = {
            "janus" => "message",
            "transaction" => generate_tx_id,
            "apisecret" => @api_secret,
            "body" => {
              "request" => "exists",
              "room" => room_id
            }
          }

          post("#{@base_url}/#{session_id}/#{plugin_handle}", payload)
        ensure
          destroy_janus_session(session_id)
        end
      end

      def generate_janus_room_id
        loop do
          candidate_room_id = rand(100_000..9_999_999)
          exists_data = get_janus_room(candidate_room_id)
          plugin_data = exists_data.fetch("plugindata", {}).fetch("data", {})

          unless plugin_data.key?("exists")
            raise JanusError,
              "Janus response missing 'exists' field for room #{candidate_room_id}"
          end

          return candidate_room_id unless plugin_data["exists"]
        end
      end

      def create_janus_room
        session_id = create_janus_session

        begin
          plugin_handle = attach_plugin_handle(session_id, "janus.plugin.videoroom")
          janus_room_id = generate_janus_room_id

          payload = {
            "janus" => "message",
            "transaction" => generate_tx_id,
            "apisecret" => @api_secret,
            "body" => {
              "request" => "create",
              "room" => janus_room_id
            }
          }

          post("#{@base_url}/#{session_id}/#{plugin_handle}", payload)
          janus_room_id
        ensure
          destroy_janus_session(session_id)
        end
      end

      def list_janus_rooms
        session_id = create_janus_session
        handle_id = attach_plugin_handle(session_id, "janus.plugin.videoroom")

        data = post(
          "#{@base_url}/#{session_id}/#{handle_id}",
          {
            janus: "message",
            body: {
              request: "list"
            },
            transaction: generate_tx_id,
            apisecret: @api_secret
          }
        )

        data.dig("plugindata", "data", "list") || []
      ensure
        destroy_janus_session(session_id)
      end

      def destroy_janus_room(janus_room_id, permanent: false)
        session_id = create_janus_session
        handle_id = attach_plugin_handle(session_id, "janus.plugin.videoroom")

        post(
          "#{@base_url}/#{session_id}/#{handle_id}",
          {
            janus: "message",
            body: {
              request: "destroy",
              room: janus_room_id,
              permanent: permanent
            },
            transaction: generate_tx_id,
            apisecret: @api_secret
          }
        )
      ensure
        destroy_janus_session(session_id)
      end
    end
  end
end
