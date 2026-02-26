# frozen_string_literal: true

require "test_helper"

class TestConversation < Minitest::Test
  def setup
    @conversation = Cortana::Conversation.new
  end

  def test_initial_messages_empty
    assert_empty @conversation.messages
  end

  def test_initial_system_prompt_nil
    assert_nil @conversation.system_prompt
  end

  def test_add_user_message
    @conversation.add_message(:user, "Hello")
    assert_equal [{ role: :user, content: "Hello" }], @conversation.messages
  end

  def test_add_assistant_message
    @conversation.add_message(:assistant, "Hi there")
    assert_equal [{ role: :assistant, content: "Hi there" }], @conversation.messages
  end

  def test_add_message_with_string_role
    @conversation.add_message("user", "Hello")
    assert_equal [{ role: :user, content: "Hello" }], @conversation.messages
  end

  def test_add_multiple_messages
    @conversation.add_message(:user, "Hello")
    @conversation.add_message(:assistant, "Hi")
    @conversation.add_message(:user, "How are you?")

    assert_equal 3, @conversation.messages.length
    assert_equal :user, @conversation.messages[0][:role]
    assert_equal :assistant, @conversation.messages[1][:role]
    assert_equal :user, @conversation.messages[2][:role]
  end

  def test_invalid_role_raises_error
    error = assert_raises(Cortana::Error) do
      @conversation.add_message(:system, "test")
    end
    assert_includes error.message, "Invalid role"
  end

  def test_clear
    @conversation.add_message(:user, "Hello")
    @conversation.add_message(:assistant, "Hi")
    @conversation.clear

    assert_empty @conversation.messages
  end

  def test_system_prompt
    conversation = Cortana::Conversation.new(system_prompt: "You are a helpful assistant.")
    assert_equal "You are a helpful assistant.", conversation.system_prompt
  end

  def test_system_prompt_setter
    @conversation.system_prompt = "New prompt"
    assert_equal "New prompt", @conversation.system_prompt
  end

  def test_to_api_messages
    @conversation.add_message(:user, "Hello")
    @conversation.add_message(:assistant, "Hi")

    api_messages = @conversation.to_api_messages
    assert_equal [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hi" }
    ], api_messages
  end

  def test_to_api_messages_empty
    assert_empty @conversation.to_api_messages
  end

  def test_large_number_of_messages
    100.times do |i|
      role = i.even? ? :user : :assistant
      @conversation.add_message(role, "Message #{i}")
    end

    assert_equal 100, @conversation.messages.length
    assert_equal 100, @conversation.to_api_messages.length
  end
end
