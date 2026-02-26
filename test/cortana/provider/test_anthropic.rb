# frozen_string_literal: true

require "test_helper"

class TestProviderAnthropic < Minitest::Test
  def setup
    @config = Cortana::Configuration.new
    @config.use(provider: :anthropic, api_key: "test-key", model: "claude-opus-4-20250514")
    @provider = Cortana::Provider::Anthropic.new(@config)
    @conversation = Cortana::Conversation.new
    @conversation.add_message(:user, "Hello")
  end

  def test_supported_models
    models = Cortana::Provider::Anthropic.supported_models
    assert_includes models, "claude-opus-4-20250514"
    assert_includes models, "claude-sonnet-4-20250514"
  end

  def test_chat_sends_correct_request
    stub_anthropic_stream("Hello!")

    response = @provider.chat(@conversation)
    assert_equal "Hello!", response
  end

  def test_chat_with_block_streams_text
    stub_anthropic_stream("Hello!")

    chunks = []
    @provider.chat(@conversation) { |text| chunks << text }
    assert_equal ["Hello!"], chunks
  end

  def test_chat_with_system_prompt
    @conversation.system_prompt = "You are helpful."
    stub_anthropic_stream("Hi!")

    request = nil
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with do |req|
      request = req
      true
    end
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: sse_body("Hi!")
      )

    @provider.chat(@conversation)
    body = JSON.parse(request.body)
    assert_equal "You are helpful.", body["system"]
  end

  def test_chat_sends_correct_headers
    stub_anthropic_stream("OK")

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "x-api-key" => "test-key",
          "anthropic-version" => "2023-06-01"
        }
      )
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: sse_body("OK")
      )

    @provider.chat(@conversation)
  end

  def test_chat_handles_401_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 401, body: '{"error":"unauthorized"}')

    assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
  end

  def test_chat_handles_429_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 429, body: '{"error":"rate_limited"}')

    error = assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
    assert_includes error.message, "429"
  end

  def test_chat_handles_500_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: '{"error":"internal_error"}')

    error = assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
    assert_includes error.message, "500"
  end

  def test_chat_handles_empty_response
    body = "event: message_start\ndata: {\"type\":\"message_start\"}\n\n" \
           "event: message_stop\ndata: {\"type\":\"message_stop\"}\n\n"

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: body
      )

    response = @provider.chat(@conversation)
    assert_equal "", response
  end

  def test_chat_handles_multi_chunk_sse
    body = sse_body("Hello") + sse_body(" World")

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: body
      )

    chunks = []
    response = @provider.chat(@conversation) { |text| chunks << text }
    assert_equal "Hello World", response
    assert_equal ["Hello", " World"], chunks
  end

  private

  def stub_anthropic_stream(text)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: sse_body(text)
      )
  end

  def sse_body(text)
    "event: content_block_delta\n" \
      "data: {\"type\":\"content_block_delta\",\"delta\":{\"type\":\"text_delta\",\"text\":\"#{text}\"}}\n\n"
  end
end
