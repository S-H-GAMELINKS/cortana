# frozen_string_literal: true

module Cortana
  class CLI
    def initialize(provider: nil, conversation: nil)
      @provider = provider || Cortana.provider
      @conversation = conversation || Conversation.new
    end

    def start
      puts "Cortana v#{VERSION} (#{Cortana.configuration.provider})"
      puts "Type your message and press Enter twice to send. Type 'exit' or 'quit' to quit."
      puts

      loop do
        input = read_input
        break if input.nil?

        input = input.strip
        next if input.empty?
        break if %w[exit quit].include?(input.downcase)

        handle_input(input)
      end
    rescue Interrupt
      puts "\nGoodbye!"
    end

    private

    def read_input
      Reline.readmultiline("cortana> ", true) do |input|
        input.end_with?("\n\n")
      end
    rescue Interrupt
      puts
      nil
    end

    def handle_input(input)
      @conversation.add_message(:user, input)

      response = +""
      begin
        @provider.chat(@conversation) do |text|
          print text
          response << text
        end
      rescue Interrupt
        # Streaming interrupted by Ctrl+C
      end
      puts

      @conversation.add_message(:assistant, response) unless response.empty?
    end
  end
end
