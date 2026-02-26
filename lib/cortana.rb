# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "reline"

require_relative "cortana/version"
require_relative "cortana/configuration"
require_relative "cortana/conversation"
require_relative "cortana/provider/base"
require_relative "cortana/provider/anthropic"
require_relative "cortana/provider/open_ai"
require_relative "cortana/provider/ollama"
require_relative "cortana/tool"
require_relative "cortana/skill"
require_relative "cortana/cli"

module Cortana
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ProviderError < Error; end
  class ProviderNotImplementedError < Error; end
  class ToolNotImplementedError < Error; end
  class SkillNotImplementedError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def provider
      @provider ||= Provider.build(configuration)
    end

    def reset!
      @configuration = nil
      @provider = nil
    end
  end
end
