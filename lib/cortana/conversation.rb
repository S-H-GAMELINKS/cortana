# frozen_string_literal: true

module Cortana
  class Conversation
    VALID_ROLES = %i[user assistant].freeze

    attr_reader :messages
    attr_accessor :system_prompt

    def initialize(system_prompt: nil)
      @messages = []
      @system_prompt = system_prompt
    end

    def add_message(role, content)
      role = role.to_sym
      raise Error, "Invalid role: #{role}. Must be one of: #{VALID_ROLES.join(", ")}" unless VALID_ROLES.include?(role)

      @messages << { role: role, content: content }
    end

    def clear
      @messages.clear
    end

    def to_api_messages
      @messages.map { |m| { role: m[:role].to_s, content: m[:content] } }
    end
  end
end
