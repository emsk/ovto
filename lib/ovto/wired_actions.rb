require 'native'
require 'promise'

module Ovto
  class WiredActions
    def initialize(actions, app, runtime)
      @actions, @app, @runtime = actions, app, runtime
    end

    def method_missing(name, args_hash={})
      Ovto.log_error {
        invoke_action(name, args_hash)
      }
    end

    def respond_to?(name)
      @actions.respond_to?(name)
    end

    private

    # Call action and schedule rendering
    def invoke_action(name, args_hash)
      kwargs = {state: @app.state}.merge(args_hash)
      state_diff = @actions.__send__(name, **kwargs)
      return if state_diff.nil? || state_diff.is_a?(Promise) || `!!state_diff.then`

      if native?(state_diff)
        raise "action `#{name}' returned js object: #{`name.toString()`}"
      end
      unless state_diff.is_a?(Hash)
        raise "action `#{name}' must return hash but got #{state_diff.inspect}"
      end
      new_state = @app.state.merge(state_diff)
      if new_state != @app.state
        @runtime.scheduleRender
        @app._set_state(new_state)
      end
      return new_state
    end
  end
end
