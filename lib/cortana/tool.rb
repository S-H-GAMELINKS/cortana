# frozen_string_literal: true

module Cortana
  class Tool
    def name
      raise ToolNotImplementedError, "#{self.class}#name is not implemented"
    end

    def description
      raise ToolNotImplementedError, "#{self.class}#description is not implemented"
    end

    def parameters
      raise ToolNotImplementedError, "#{self.class}#parameters is not implemented"
    end

    def execute(**_params)
      raise ToolNotImplementedError, "#{self.class}#execute is not implemented"
    end
  end
end
