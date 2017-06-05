module Instrumental
  class Redis < Reporter

    def self.enabled?
      !!defined?(::Redis)
    end

    def instrument
      return if ::Redis::Client.method_defined?(:call_with_instrumental_trace)
      ::Redis::Client.class_eval do
        def call_with_instrumental_trace(*args, &blk)
          start_time = Time.now
          begin
            call_without_instrumental_trace(*args, &blk)
          ensure
            method_name = args[0].is_a?(Array) ? args[0][0] : args[0]
            InstrumentalReporters.gauge("redis.#{method_name}", (Time.now - start_time).to_f)
          end
        end
        alias_method :call_without_instrumental_trace, :call
        alias_method :call, :call_with_instrumental_trace
      end
    end

  end
end
