# frozen_string_literal: true

module Cortana
  module Provider
    class OpenAI < Base
      ENDPOINT = "https://api.openai.com/v1/chat/completions"

      SUPPORTED_MODELS = %w[
        gpt-4o
        gpt-4o-mini
        gpt-4-turbo
        gpt-4
        gpt-3.5-turbo
        o1
        o1-mini
        o3-mini
      ].freeze

      def self.supported_models
        SUPPORTED_MODELS
      end

      def chat(conversation, &)
        uri = URI.parse(ENDPOINT)

        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{configuration.api_key}"
        }

        body = build_body(conversation)

        post_stream(uri, headers: headers, body: body, &)
      end

      private

      def build_body(conversation)
        messages = conversation.to_api_messages

        messages = [{ role: "system", content: conversation.system_prompt }] + messages if conversation.system_prompt

        {
          model: configuration.model || SUPPORTED_MODELS.first,
          messages: messages,
          stream: true
        }
      end

      def parse_sse_event(event_str)
        event_str.each_line do |line|
          line = line.strip
          next unless line.start_with?("data: ")

          data = line.delete_prefix("data: ")
          next if data == "[DONE]"

          parsed = JSON.parse(data)
          text = parsed.dig("choices", 0, "delta", "content")
          yield text if text
        end
      end
    end
  end
end
