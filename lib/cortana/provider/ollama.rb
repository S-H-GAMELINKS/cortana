# frozen_string_literal: true

module Cortana
  module Provider
    class Ollama < Base
      DEFAULT_HOST = "http://localhost:11434"

      def self.supported_models
        fetch_models
      rescue StandardError
        []
      end

      def self.fetch_models
        host = ENV.fetch("OLLAMA_HOST", DEFAULT_HOST)
        uri = URI.parse("#{host}/api/tags")
        response = Net::HTTP.get_response(uri)
        return [] unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body).fetch("models", []).map { |m| m["name"] }
      end

      def chat(conversation, &)
        uri = URI.parse("#{host}/api/chat")

        headers = { "Content-Type" => "application/json" }
        body = build_body(conversation)

        post_ndjson_stream(uri, headers: headers, body: body, &)
      end

      private

      def host
        ENV.fetch("OLLAMA_HOST", DEFAULT_HOST)
      end

      def build_body(conversation)
        messages = conversation.to_api_messages

        messages = [{ role: "system", content: conversation.system_prompt }] + messages if conversation.system_prompt

        {
          model: configuration.model,
          messages: messages,
          stream: true
        }
      end

      def post_ndjson_stream(uri, headers:, body:, &block)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

        request = Net::HTTP::Post.new(uri.path, headers)
        request.body = JSON.generate(body)

        full_response = +""
        buffer = +""

        http.request(request) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            response_body = begin
              response.read_body
            rescue StandardError
              ""
            end
            raise ProviderError, "HTTP #{response.code}: #{response_body}"
          end

          response.read_body do |chunk|
            buffer << chunk

            while (idx = buffer.index("\n"))
              line = buffer.slice!(0, idx + 1).strip
              next if line.empty?

              parse_ndjson_line(line) do |text|
                full_response << text
                block&.call(text)
              end
            end
          end
        end

        full_response
      end

      def parse_ndjson_line(line)
        parsed = JSON.parse(line)
        text = parsed.dig("message", "content")
        yield text if text && !text.empty?
      end
    end
  end
end
