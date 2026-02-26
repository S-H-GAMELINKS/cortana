# frozen_string_literal: true

require_relative "test_helper"

class TestE2EChatFlow < Minitest::Test
  def test_basic_chat_flow
    runner = ScriptRunner.new

    runner
      .input("Hello")
      .assert_output_contains("Mock response from Cortana")
      .assert_conversation_length(2)
      .assert_last_role(:assistant)
  end

  def test_multi_turn_conversation
    runner = ScriptRunner.new

    runner
      .input("Hello")
      .assert_conversation_length(2)
      .input("How are you?")
      .assert_conversation_length(4)
      .input("Tell me more")
      .assert_conversation_length(6)
  end

  def test_conversation_roles_alternate
    runner = ScriptRunner.new

    runner.input("Hello")

    messages = runner.conversation.messages
    assert_equal :user, messages[0][:role]
    assert_equal :assistant, messages[1][:role]
  end

  def test_user_message_preserved
    runner = ScriptRunner.new

    runner.input("My specific question")

    messages = runner.conversation.messages
    assert_equal "My specific question", messages[0][:content]
  end

  def test_assistant_response_preserved
    runner = ScriptRunner.new

    runner.input("Hello")

    messages = runner.conversation.messages
    assert_equal Cortana::Provider::Mock::RESPONSE, messages[1][:content]
  end
end
