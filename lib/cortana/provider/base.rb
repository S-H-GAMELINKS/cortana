# frozen_string_literal: true

module Cortana
  module Provider
    class Base
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def chat(_conversation)
        raise ProviderNotImplementedError, "#{self.class}#chat is not implemented"
      end

      def self.supported_models
        raise ProviderNotImplementedError, "#{name}.supported_models is not implemented"
      end

      private

      def post_stream(uri, headers:, body:, &block)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

        request = Net::HTTP::Post.new(uri.path, headers)
        request.body = JSON.generate(body)

        full_response = +""
        sse_buffer = +""

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
            sse_buffer << chunk

            while (idx = sse_buffer.index("\n\n"))
              event_str = sse_buffer.slice!(0, idx + 2)
              parse_sse_event(event_str) do |text|
                full_response << text
                block&.call(text)
              end
            end
          end
        end

        unless sse_buffer.strip.empty?
          parse_sse_event(sse_buffer) do |text|
            full_response << text
            block&.call(text)
          end
        end

        full_response
      end

      def parse_sse_event(_event_str)
        raise ProviderNotImplementedError, "#{self.class}#parse_sse_event is not implemented"
      end
    end

    class << self
      def for(provider_name)
        case provider_name
        when :anthropic then Anthropic
        when :open_ai then OpenAI
        when :ollama then Ollama
        else raise ConfigurationError, "Unknown provider: #{provider_name}"
        end
      end

      def build(configuration)
        self.for(configuration.provider).new(configuration)
      end
    end
  end
end
