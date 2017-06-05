module Instrumental
  class NetHttp < Reporter
    def self.enabled?
      true
    end

    def instrument
      return if ::Net::HTTP.method_defined?(:request_with_instrumental_trace)

      ::Net::HTTP.class_eval do

        def request_with_instrumental_trace(req, body = nil, &block)
          start_time = Time.now
          begin
            request_without_instrumental_trace(req, body, &block)
          ensure
            InstrumentalReporters.agent.gauge("service.request", (Time.now - start_time).to_f)
          end
        end

        alias_method :request_without_instrumental_trace, :request
        alias_method :request, :request_with_instrumental_trace
      end

    end
  end
end
