# frozen_string_literal: true

require_relative "test_helper"

class TestE2EMultiLineInput < Minitest::Test
  def test_multi_line_message
    runner = ScriptRunner.new

    runner
      .input("Line 1\nLine 2\nLine 3")
      .assert_conversation_length(2)

    messages = runner.conversation.messages
    assert_equal "Line 1\nLine 2\nLine 3", messages[0][:content]
  end

  def test_empty_lines_in_message
    runner = ScriptRunner.new

    runner
      .input("Before\n\nAfter")
      .assert_conversation_length(2)

    messages = runner.conversation.messages
    assert_equal "Before\n\nAfter", messages[0][:content]
  end

  def test_multi_line_then_single_line
    runner = ScriptRunner.new

    runner
      .input("Line 1\nLine 2")
      .assert_conversation_length(2)
      .input("Single line")
      .assert_conversation_length(4)

    messages = runner.conversation.messages
    assert_equal "Line 1\nLine 2", messages[0][:content]
    assert_equal "Single line", messages[2][:content]
  end
end
