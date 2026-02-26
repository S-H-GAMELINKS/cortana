# frozen_string_literal: true

require "test_helper"

class TestTool < Minitest::Test
  def setup
    @tool = Cortana::Tool.new
  end

  def test_name_raises_not_implemented
    assert_raises(Cortana::ToolNotImplementedError) { @tool.name }
  end

  def test_description_raises_not_implemented
    assert_raises(Cortana::ToolNotImplementedError) { @tool.description }
  end

  def test_parameters_raises_not_implemented
    assert_raises(Cortana::ToolNotImplementedError) { @tool.parameters }
  end

  def test_execute_raises_not_implemented
    assert_raises(Cortana::ToolNotImplementedError) { @tool.execute }
  end
end
