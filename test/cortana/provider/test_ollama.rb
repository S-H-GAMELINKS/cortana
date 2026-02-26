# frozen_string_literal: true

require "test_helper"

class TestProviderOllama < Minitest::Test
  def setup
    @config = Cortana::Configuration.new
    @config.use(provider: :ollama, model: "gemma3:4b")
    @provider = Cortana::Provider::Ollama.new(@config)
    @conversation = Cortana::Conversation.new
    @conversation.add_message(:user, "Hello")
  end

  def test_chat_sends_correct_request
    stub_ollama_stream("Hello!")

    response = @provider.chat(@conversation)
    assert_equal "Hello!", response
  end

  def test_chat_with_block_streams_text
    stub_ollama_stream("Hello!")

    chunks = []
    @provider.chat(@conversation) { |text| chunks << text }
    assert_equal ["Hello!"], chunks
  end

  def test_chat_with_system_prompt
    @conversation.system_prompt = "You are helpful."

    request = nil
    stub_request(:post, "http://localhost:11434/api/chat")
      .with do |req|
      request = req
      true
    end
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: ndjson_body("Hi!")
      )

    @provider.chat(@conversation)
    body = JSON.parse(request.body)
    assert_equal "system", body["messages"][0]["role"]
    assert_equal "You are helpful.", body["messages"][0]["content"]
    assert_equal "user", body["messages"][1]["role"]
  end

  def test_chat_sends_correct_model
    request = nil
    stub_request(:post, "http://localhost:11434/api/chat")
      .with do |req|
      request = req
      true
    end
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: ndjson_body("OK")
      )

    @provider.chat(@conversation)
    body = JSON.parse(request.body)
    assert_equal "gemma3:4b", body["model"]
  end

  def test_chat_handles_401_error
    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(status: 401, body: '{"error":"unauthorized"}')

    assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
  end

  def test_chat_handles_500_error
    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(status: 500, body: '{"error":"internal_error"}')

    error = assert_raises(Cortana::ProviderError) do
      @provider.chat(@conversation)
    end
    assert_includes error.message, "500"
  end

  def test_chat_handles_empty_response
    body = "{\"message\":{\"role\":\"assistant\",\"content\":\"\"},\"done\":true}\n"

    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body
      )

    response = @provider.chat(@conversation)
    assert_equal "", response
  end

  def test_chat_handles_multi_chunk_ndjson
    body = ndjson_body("Hello") + ndjson_body(" World")

    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body
      )

    chunks = []
    response = @provider.chat(@conversation) { |text| chunks << text }
    assert_equal "Hello World", response
    assert_equal ["Hello", " World"], chunks
  end

  def test_supported_models_fetches_from_api
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(
        status: 200,
        body: '{"models":[{"name":"gemma3:4b"},{"name":"llama3.2:3b"}]}'
      )

    models = Cortana::Provider::Ollama.supported_models
    assert_includes models, "gemma3:4b"
    assert_includes models, "llama3.2:3b"
  end

  def test_supported_models_returns_empty_on_error
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(status: 500, body: "")

    models = Cortana::Provider::Ollama.supported_models
    assert_empty models
  end

  def test_supported_models_returns_empty_on_connection_error
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_raise(Errno::ECONNREFUSED)

    models = Cortana::Provider::Ollama.supported_models
    assert_empty models
  end

  private

  def stub_ollama_stream(text)
    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: ndjson_body(text)
      )
  end

  def ndjson_body(text)
    "{\"message\":{\"role\":\"assistant\",\"content\":\"#{text}\"},\"done\":false}\n"
  end
end
