module Instrumental
  class Redis < Reporter

    def self.enabled?
      !!defined?(::Redis) &&
        InstrumentalReporters.configuration[:cache][:enabled]
    end

    def instrument
      return if ::Redis::Client.method_defined?(:call_with_instrumental_trace)
      ::Redis::Client.class_eval do
        def call_with_instrumental_trace(*args, &blk)
          start_time = Time.now
          begin
            call_without_instrumental_trace(*args, &blk)
          ensure
            duration = (Time.now - start_time).to_f
            InstrumentalReporters.gauge("cache.command", duration) if InstrumentalReporters.configuration[:cache][:command][:enabled]
            if InstrumentalReporters.configuration[:cache][:specific][:enabled]
              method_name = args[0].is_a?(Array) ? args[0][0] : args[0]
              InstrumentalReporters.gauge("cache.command.#{method_name}", duration)
            end
          end
        end
        alias_method :call_without_instrumental_trace, :call
        alias_method :call, :call_with_instrumental_trace
      end
    end

  end
end
