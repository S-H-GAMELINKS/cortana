# frozen_string_literal: true

require_relative "../test_helper"

module Cortana
  module Provider
    class Mock < Base
      RESPONSE = "Mock response from Cortana"

      def self.supported_models
        %w[mock-model]
      end

      def chat(_conversation, &block)
        block&.call(RESPONSE)
        RESPONSE
      end
    end
  end
end

class ScriptRunner
  attr_reader :cli, :conversation, :output

  def initialize
    config = Cortana::Configuration.new
    config.use(provider: :anthropic, api_key: "test", model: "claude-opus-4-20250514")
    @provider = Cortana::Provider::Mock.new(config)
    @conversation = Cortana::Conversation.new
    @cli = Cortana::CLI.new(provider: @provider, conversation: @conversation)
    @output = +""
  end

  def input(text)
    @conversation.add_message(:user, text)

    captured = capture_output do
      @provider.chat(@conversation) do |chunk|
        print chunk
      end
    end
    @output << captured

    response = Cortana::Provider::Mock::RESPONSE
    @conversation.add_message(:assistant, response)

    self
  end

  def assert_output_contains(text)
    raise "Expected output to contain '#{text}', got '#{@output}'" unless @output.include?(text)

    self
  end

  def assert_conversation_length(expected)
    actual = @conversation.messages.length
    raise "Expected conversation length #{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_last_role(role)
    actual = @conversation.messages.last[:role]
    raise "Expected last role to be #{role}, got #{actual}" unless actual == role.to_sym

    self
  end

  private

  def capture_output
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
