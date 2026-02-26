# Cortana

Cortana is a Ruby-based LLM agent that supports multiple providers with an extensible architecture. It provides a CLI interface powered by Reline for multi-line input and streams responses in real-time.

## Features

- **Multi-provider support** - Anthropic, OpenAI, and Ollama out of the box, easily extensible
- **Ruby DSL configuration** - Configure via `~/.cortanarc` (global) and `.lcortanarc` (per-project)
- **Multi-line input** - Powered by Reline with history support
- **Streaming responses** - Real-time token display via SSE (Anthropic, OpenAI) and NDJSON (Ollama)
- **Extensible** - Tool and Skill interfaces for future expansion

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add cortana
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install cortana
```

## Configuration

Cortana is configured via Ruby DSL files. Create `~/.cortanarc` for global settings:

```ruby
# ~/.cortanarc
use provider: :anthropic
use api_key: "sk-ant-..."
use model: "claude-sonnet-4-20250514"
```

### Per-project configuration

Create `.lcortanarc` in your project root to override global settings:

```ruby
# .lcortanarc
use provider: :open_ai
use api_key: "sk-..."
use model: "gpt-4o"
```

Local settings take priority over global settings. You can also partially override — for example, only changing the model while keeping the global provider and API key:

```ruby
# .lcortanarc
use model: "claude-opus-4-20250514"
```

### Supported providers and models

**Anthropic** (`:anthropic`)
- `claude-opus-4-20250514`
- `claude-sonnet-4-20250514`
- `claude-haiku-4-20250414`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`

**OpenAI** (`:open_ai`)
- `gpt-4o`, `gpt-4o-mini`
- `gpt-4-turbo`, `gpt-4`
- `gpt-3.5-turbo`
- `o1`, `o1-mini`, `o3-mini`

**Ollama** (`:ollama`) — local models, no API key required
- Any model available via `ollama list` (e.g. `gemma3:4b`, `llama3.2:3b`)
- Models are fetched dynamically from the running Ollama instance

```ruby
# ~/.cortanarc
use provider: :ollama
use model: "gemma3:4b"
```

By default, Cortana connects to `http://localhost:11434`. Set the `OLLAMA_HOST` environment variable to use a different host.

## Usage

```bash
cortana
```

Type your message and press Enter twice (empty line) to send. The response will be streamed in real-time.

```
cortana> Hello, what can you do?

I'm an AI assistant that can help you with a variety of tasks...

cortana> Write a Ruby method
that calculates fibonacci numbers

def fibonacci(n)
  return n if n <= 1
  fibonacci(n - 1) + fibonacci(n - 2)
end
```

- **Enter twice** — send message
- **Ctrl+C** — interrupt streaming response
- **exit** / **quit** — quit Cortana

## Extending Cortana

### Adding a new provider

Subclass `Cortana::Provider::Base` and implement `chat`, `parse_sse_event`, and `self.supported_models`:

```ruby
class Cortana::Provider::MyProvider < Cortana::Provider::Base
  SUPPORTED_MODELS = %w[my-model-v1].freeze

  def self.supported_models
    SUPPORTED_MODELS
  end

  def chat(conversation, &)
    # Build request and call post_stream
  end

  private

  def parse_sse_event(event_str)
    # Parse SSE event and yield text chunks
  end
end
```

### Tools and Skills

Cortana provides extension points for tools (function calling) and skills (slash commands). These interfaces are available for subclassing:

```ruby
# Tool: executed by the LLM via function calling
class MyTool < Cortana::Tool
  def name = "my_tool"
  def description = "Does something useful"
  def parameters = { type: "object", properties: {} }
  def execute(**params) = "result"
end

# Skill: invoked by the user via /command
class MySkill < Cortana::Skill
  def name = "my_skill"
  def description = "A custom skill"
  def execute(context) = "skill output"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```bash
bundle exec rake test      # Run tests
bundle exec rubocop        # Run linter
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/S-H-GAMELINKS/cortana.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
