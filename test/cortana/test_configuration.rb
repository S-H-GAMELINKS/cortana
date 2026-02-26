# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TestConfiguration < Minitest::Test
  def setup
    @config = Cortana::Configuration.new
  end

  # --- use DSL ---

  def test_use_sets_provider
    @config.use(provider: :anthropic)
    assert_equal :anthropic, @config.provider
  end

  def test_use_sets_api_key
    @config.use(api_key: "test-key")
    assert_equal "test-key", @config.api_key
  end

  def test_use_sets_model
    @config.use(model: "claude-opus-4-20250514")
    assert_equal "claude-opus-4-20250514", @config.model
  end

  def test_use_sets_multiple_options
    @config.use(provider: :anthropic, api_key: "key", model: "claude-opus-4-20250514")
    assert_equal :anthropic, @config.provider
    assert_equal "key", @config.api_key
    assert_equal "claude-opus-4-20250514", @config.model
  end

  def test_use_does_not_overwrite_with_nil
    @config.use(provider: :anthropic)
    @config.use(api_key: "key")
    assert_equal :anthropic, @config.provider
    assert_equal "key", @config.api_key
  end

  # --- validate! ---

  def test_validate_raises_without_provider
    @config.use(api_key: "key")
    error = assert_raises(Cortana::ConfigurationError) { @config.validate! }
    assert_includes error.message, "Provider"
  end

  def test_validate_raises_without_api_key
    @config.use(provider: :anthropic)
    error = assert_raises(Cortana::ConfigurationError) { @config.validate! }
    assert_includes error.message, "API key"
  end

  def test_validate_raises_for_unknown_provider
    @config.use(provider: :unknown, api_key: "key")
    error = assert_raises(Cortana::ConfigurationError) { @config.validate! }
    assert_includes error.message, "Unknown provider"
  end

  def test_validate_raises_for_unsupported_model
    @config.use(provider: :anthropic, api_key: "key", model: "nonexistent-model")
    error = assert_raises(Cortana::ConfigurationError) { @config.validate! }
    assert_includes error.message, "Unsupported model"
    assert_includes error.message, "nonexistent-model"
  end

  def test_validate_passes_with_valid_anthropic_config
    @config.use(provider: :anthropic, api_key: "key", model: "claude-opus-4-20250514")
    @config.validate!
  end

  def test_validate_passes_with_valid_openai_config
    @config.use(provider: :open_ai, api_key: "key", model: "gpt-4o")
    @config.validate!
  end

  def test_validate_passes_with_ollama_without_api_key
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(status: 200, body: '{"models":[{"name":"gemma3:4b"}]}')

    @config.use(provider: :ollama, model: "gemma3:4b")
    @config.validate!
  end

  def test_validate_raises_without_api_key_for_non_ollama
    @config.use(provider: :anthropic)
    error = assert_raises(Cortana::ConfigurationError) { @config.validate! }
    assert_includes error.message, "API key"
  end

  def test_validate_passes_without_model
    @config.use(provider: :anthropic, api_key: "key")
    @config.validate!
  end

  def test_validate_raises_for_model_wrong_provider
    @config.use(provider: :anthropic, api_key: "key", model: "gpt-4o")
    assert_raises(Cortana::ConfigurationError) { @config.validate! }
  end

  # --- allow_tools / allow_tool / skill stubs ---

  def test_allow_tools
    @config.allow_tools(:shell, :file_read)
    assert_equal %i[shell file_read], @config.allowed_tools
  end

  def test_allow_tool
    @config.allow_tool(:shell) {}
    assert_includes @config.allowed_tools, :shell
  end

  def test_skill_stub
    @config.skill(:commit) {}
    assert @config.skills.key?(:commit)
  end

  # --- load! with config files ---

  def test_load_global_rc_only
    with_rc_files(global: <<~RUBY) do |global_path, local_path|
      use provider: :anthropic
      use api_key: "global-key"
      use model: "claude-opus-4-20250514"
    RUBY
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal :anthropic, @config.provider
      assert_equal "global-key", @config.api_key
      assert_equal "claude-opus-4-20250514", @config.model
    end
  end

  def test_load_local_rc_only
    with_rc_files(local: <<~RUBY) do |global_path, local_path|
      use provider: :open_ai
      use api_key: "local-key"
      use model: "gpt-4o"
    RUBY
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal :open_ai, @config.provider
      assert_equal "local-key", @config.api_key
      assert_equal "gpt-4o", @config.model
    end
  end

  def test_local_rc_overrides_global
    with_rc_files(
      global: <<~RUBY,
        use provider: :anthropic
        use api_key: "global-key"
        use model: "claude-opus-4-20250514"
      RUBY
      local: <<~RUBY
        use provider: :open_ai
        use api_key: "local-key"
        use model: "gpt-4o"
      RUBY
    ) do |global_path, local_path|
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal :open_ai, @config.provider
      assert_equal "local-key", @config.api_key
      assert_equal "gpt-4o", @config.model
    end
  end

  def test_partial_local_override
    with_rc_files(
      global: <<~RUBY,
        use provider: :anthropic
        use api_key: "global-key"
        use model: "claude-opus-4-20250514"
      RUBY
      local: <<~RUBY
        use model: "claude-sonnet-4-20250514"
      RUBY
    ) do |global_path, local_path|
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal :anthropic, @config.provider
      assert_equal "global-key", @config.api_key
      assert_equal "claude-sonnet-4-20250514", @config.model
    end
  end

  def test_local_overrides_different_provider_both_valid
    with_rc_files(
      global: <<~RUBY,
        use provider: :anthropic
        use api_key: "anthropic-key"
        use model: "claude-opus-4-20250514"
      RUBY
      local: <<~RUBY
        use provider: :open_ai
        use api_key: "openai-key"
        use model: "gpt-4o"
      RUBY
    ) do |global_path, local_path|
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal :open_ai, @config.provider
      assert_equal "openai-key", @config.api_key
      assert_equal "gpt-4o", @config.model
    end
  end

  def test_local_overrides_with_invalid_model_for_provider
    with_rc_files(
      global: <<~RUBY,
        use provider: :anthropic
        use api_key: "key"
        use model: "claude-opus-4-20250514"
      RUBY
      local: <<~RUBY
        use provider: :open_ai
        use model: "claude-opus-4-20250514"
      RUBY
    ) do |global_path, local_path|
      assert_raises(Cortana::ConfigurationError) do
        @config.load!(global_path: global_path, local_path: local_path)
      end
    end
  end

  def test_invalid_global_valid_local_override
    with_rc_files(
      global: <<~RUBY,
        use provider: :anthropic
        use api_key: "key"
        use model: "invalid-model"
      RUBY
      local: <<~RUBY
        use model: "claude-opus-4-20250514"
      RUBY
    ) do |global_path, local_path|
      @config.load!(global_path: global_path, local_path: local_path)
      assert_equal "claude-opus-4-20250514", @config.model
    end
  end

  def test_no_config_files_raises_error
    Dir.mktmpdir do |dir|
      assert_raises(Cortana::ConfigurationError) do
        @config.load!(
          global_path: File.join(dir, "nonexistent"),
          local_path: File.join(dir, "nonexistent2")
        )
      end
    end
  end

  def test_empty_config_file
    with_rc_files(global: "") do |global_path, local_path|
      assert_raises(Cortana::ConfigurationError) do
        @config.load!(global_path: global_path, local_path: local_path)
      end
    end
  end

  private

  def with_rc_files(global: nil, local: nil)
    Dir.mktmpdir do |dir|
      global_path = File.join(dir, ".cortanarc")
      local_path = File.join(dir, ".lcortanarc")

      File.write(global_path, global) if global
      File.write(local_path, local) if local

      global_path = File.join(dir, "nonexistent_global") unless global
      local_path = File.join(dir, "nonexistent_local") unless local

      yield global_path, local_path
    end
  end
end
