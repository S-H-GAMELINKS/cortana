# frozen_string_literal: true

require "test_helper"

class TestCortana < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Cortana::VERSION
  end

  def test_error_class_hierarchy
    assert Cortana::ConfigurationError < Cortana::Error
    assert Cortana::ProviderError < Cortana::Error
    assert Cortana::ProviderNotImplementedError < Cortana::Error
    assert Cortana::ToolNotImplementedError < Cortana::Error
    assert Cortana::SkillNotImplementedError < Cortana::Error
  end

  def test_reset_clears_configuration_and_provider
    Cortana.configuration
    Cortana.reset!

    # After reset, configuration should be a new instance
    config = Cortana.configuration
    assert_nil config.provider
    assert_nil config.api_key
  end
end
