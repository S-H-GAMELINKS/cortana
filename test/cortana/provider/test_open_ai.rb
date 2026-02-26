# frozen_string_literal: true

require "test_helper"

class TestProviderOpenAI < Minitest::Test
  def setup
    @config = Cortana::Configuration.new
    @config.use(provider: :open_ai, api_key: "test-key", model: "gpt-4o")
    @provider = Cortana::Provider::OpenAI.new(@config)
    @conversation = Cortana::Conversation.new
    @conversation.add_message(:user, "Hello")
  end

  def test_supported_models
    models = Cortana::Provider::OpenAI.supported_models
    assert_includes models, "gpt-4o"
    assert_includes models, "gpt-4o-mini"
    assert_includes models, "o3-mini"
  end

  def test_chat_sends_correct_request
    stub_openai_stream("Hello!")

    response = @provider.chat(@conversation)
    assert_equal "Hello!", response
  end

  def test_chat_with_block_streams_text
    stub_openai_stream("Hello!")

    chunks = []
    @provider.chat(@conversation) { |text| chunks << text }
    assert_equal ["Hello!"], chunks
  end

  def test_chat_with_system_prompt
    @conversation.system_prompt = "You are helpful."

    request = nil
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
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
    assert_equal "system", body["messages"][0]["role"]
    assert_equal "You are helpful.", body["messages"][0]["content"]
    assert_equal "user", body["messages"][1]["role"]
  end

  def test_chat_sends_correct_headers
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer test-key"
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
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: '{"error":"unauthorized"}')

    assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
  end

  def test_chat_handles_429_error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 429, body: '{"error":"rate_limited"}')

    error = assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
    assert_includes error.message, "429"
  end

  def test_chat_handles_500_error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 500, body: '{"error":"internal_error"}')

    error = assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
    assert_includes error.message, "500"
  end

  def test_chat_handles_empty_response
    body = "data: {\"choices\":[{\"delta\":{\"role\":\"assistant\"}}]}\n\n" \
           "data: [DONE]\n\n"

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: body
      )

    response = @provider.chat(@conversation)
    assert_equal "", response
  end

  def test_chat_handles_multi_chunk_sse
    body = "#{sse_body("Hello")}#{sse_body(" World")}data: [DONE]\n\n"

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
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

  def stub_openai_stream(text)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "text/event-stream" },
        body: sse_body(text)
      )
  end

  def sse_body(text)
    "data: {\"choices\":[{\"delta\":{\"content\":\"#{text}\"}}]}\n\n"
  end
end
