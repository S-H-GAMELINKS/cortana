# frozen_string_literal: true

module Cortana
  module Provider
    class Anthropic < Base
      ENDPOINT = "https://api.anthropic.com/v1/messages"
      API_VERSION = "2023-06-01"

      SUPPORTED_MODELS = %w[
        claude-opus-4-20250514
        claude-sonnet-4-20250514
        claude-haiku-4-20250414
        claude-3-5-sonnet-20241022
        claude-3-5-haiku-20241022
      ].freeze

      def self.supported_models
        SUPPORTED_MODELS
      end

      def chat(conversation, &)
        uri = URI.parse(ENDPOINT)

        headers = {
          "Content-Type" => "application/json",
          "x-api-key" => configuration.api_key,
          "anthropic-version" => API_VERSION
        }

        body = build_body(conversation)

        post_stream(uri, headers: headers, body: body, &)
      end

      private

      def build_body(conversation)
        body = {
          model: configuration.model || SUPPORTED_MODELS.first,
          messages: conversation.to_api_messages,
          max_tokens: 4096,
          stream: true
        }

        body[:system] = conversation.system_prompt if conversation.system_prompt

        body
      end

      def parse_sse_event(event_str)
        event_str.each_line do |line|
          line = line.strip
          next unless line.start_with?("data: ")

          data = line.delete_prefix("data: ")
          next if data == "[DONE]"

          parsed = JSON.parse(data)
          next unless parsed["type"] == "content_block_delta"

          text = parsed.dig("delta", "text")
          yield text if text
        end
      end
    end
  end
end
