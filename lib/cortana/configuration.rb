# frozen_string_literal: true

module Cortana
  class Configuration
    attr_reader :provider, :api_key, :model, :allowed_tools, :skills

    GLOBAL_RC_PATH = File.expand_path("~/.cortanarc")
    LOCAL_RC_PATH = ".lcortanarc"

    def initialize
      @provider = nil
      @api_key = nil
      @model = nil
      @allowed_tools = []
      @skills = {}
    end

    def use(provider: nil, api_key: nil, model: nil)
      @provider = provider if provider
      @api_key = api_key if api_key
      @model = model if model
    end

    def allow_tools(*names)
      @allowed_tools.concat(names)
    end

    def allow_tool(name, &)
      @allowed_tools << name
    end

    def skill(name, &)
      @skills[name] = true
    end

    def load!(global_path: GLOBAL_RC_PATH, local_path: File.expand_path(LOCAL_RC_PATH))
      load_file(global_path)
      load_file(local_path)
      validate!
    end

    def validate!
      raise ConfigurationError, "Provider is not configured" unless @provider

      validate_provider!
      raise ConfigurationError, "API key is not configured" if requires_api_key? && !@api_key

      validate_model!
    end

    private

    def load_file(path)
      return unless File.exist?(path)

      content = File.read(path)
      instance_eval(content, path, 1) unless content.strip.empty?
    end

    def validate_provider!
      return if %i[anthropic open_ai ollama].include?(@provider)

      raise ConfigurationError, "Unknown provider: #{@provider}"
    end

    def requires_api_key?
      @provider != :ollama
    end

    def validate_model!
      return unless @model

      provider_class = Provider.for(@provider)
      return if provider_class.supported_models.include?(@model)

      raise ConfigurationError,
            "Unsupported model '#{@model}' for provider '#{@provider}'. " \
            "Supported models: #{provider_class.supported_models.join(", ")}"
    end
  end
end
