require 'net/http'
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
        puts uri.to_s
        payload = {
          "channel" => "##{ChatService.room_name(room_id)}",
          "text" => message
        }

        Net::HTTP.post_form(uri, payload: payload.to_json)
      end

      def rooms
        @rooms ||= begin
                     uri = URI("https://slack.com/api/channels.list?token=#{@api_token}")
                     response = JSON.parse(Net::HTTP.get(uri))
                     response["channels"].map do |room|
                       Room.new(room["id"], room["name"])
                     end
                   end
      end
    end
  end

  register_chat_service "slack", ChatService::Slack
end
