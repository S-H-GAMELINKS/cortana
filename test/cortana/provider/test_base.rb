# frozen_string_literal: true

require "test_helper"

class TestProviderBase < Minitest::Test
  def setup
    config = Cortana::Configuration.new
    config.use(provider: :anthropic, api_key: "test", model: "claude-opus-4-20250514")
    @provider = Cortana::Provider::Base.new(config)
  end

  def test_chat_raises_not_implemented
    conversation = Cortana::Conversation.new
    assert_raises(Cortana::ProviderNotImplementedError) do
      @provider.chat(conversation)
    end
  end

  def test_supported_models_raises_not_implemented
    assert_raises(Cortana::ProviderNotImplementedError) do
      Cortana::Provider::Base.supported_models
    end
  end

  def test_provider_for_anthropic
    assert_equal Cortana::Provider::Anthropic, Cortana::Provider.for(:anthropic)
  end

  def test_provider_for_open_ai
    assert_equal Cortana::Provider::OpenAI, Cortana::Provider.for(:open_ai)
  end

  def test_provider_for_unknown
    assert_raises(Cortana::ConfigurationError) do
      Cortana::Provider.for(:unknown)
    end
  end

  def test_build_creates_anthropic_provider
    config = Cortana::Configuration.new
    config.use(provider: :anthropic, api_key: "key")
    provider = Cortana::Provider.build(config)
    assert_instance_of Cortana::Provider::Anthropic, provider
  end

  def test_build_creates_openai_provider
    config = Cortana::Configuration.new
    config.use(provider: :open_ai, api_key: "key")
    provider = Cortana::Provider.build(config)
    assert_instance_of Cortana::Provider::OpenAI, provider
  end
end
