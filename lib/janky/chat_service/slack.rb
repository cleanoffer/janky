require 'net/http'
require 'net/https'
require 'json'

module Janky
  module ChatService
    class Slack
      def initialize(settings)
        @api_token = settings["JANKY_CHAT_SLACK_API_TOKEN"]
        if @api_token.nil? || @api_token.empty?
          raise Error, "JANKY_CHAT_SLACK_API_TOKEN setting is required"
        end

        @webhook_token = settings["JANKY_CHAT_SLACK_WEBHOOK_TOKEN"]
        if @webhook_token.nil? || @webhook_token.empty?
          raise Error, "JANKY_CHAT_SLACK_WEBHOOK_TOKEN setting is required"
        end

        @subdomain = settings["JANKY_CHAT_SLACK_SUBDOMAIN"]
        if @subdomain.nil? || @subdomain.empty?
          raise Error, "JANKY_CHAT_SLACK_SUBDOMAIN setting is required"
        end
      end

      def speak(message, room_id, opts={})
        uri = URI("https://#{@subdomain}.slack.com/services/hooks/incoming-webhook?token=#{@webhook_token}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(uri.request_uri)

        payload = {
          "channel" => "##{ChatService.room_name(room_id)}",
          "text" => message
        }

        request.set_form_data(payload: payload.to_json)
        #Net::HTTP.post_form(uri, payload: payload.to_json)
        response = http.request(request)
      end

      def rooms
        @rooms ||= begin
                     uri = URI("https://slack.com/api/channels.list?token=#{@api_token}")

                     http = Net::HTTP.new(uri.host, uri.port)
                     http.use_ssl = true
                     #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                     request = Net::HTTP::Get.new(uri.request_uri)
                     response = http.request(request)

                     rooms = JSON.parse(response.body)
                     rooms["channels"].map do |room|
                       Room.new(room["id"], room["name"])
                     end
                   end
      end
    end
  end

  register_chat_service "slack", ChatService::Slack
end
