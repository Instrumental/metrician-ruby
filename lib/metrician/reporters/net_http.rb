require "net/http"

module Metrician
  class NetHttp < Reporter

    REQUEST_METRIC = "outgoing_request"

    def self.enabled?
      !!defined?(Net::HTTP) &&
        Metrician.configuration[:external_service][:enabled]
    end

    def instrument
      return if ::Net::HTTP.method_defined?(:request_with_metrician_time)
      ::Net::HTTP.class_eval do
        def request_with_metrician_time(req, body = nil, &block)
          start_time = Time.now
          begin
            request_without_metrician_time(req, body, &block)
          ensure
            Metrician.gauge(REQUEST_METRIC, (Time.now - start_time).to_f) if Metrician.configuration[:external_service][:request][:enabled]
          end
        end
        alias_method :request_without_metrician_time, :request
        alias_method :request, :request_with_metrician_time
      end
    end

  end
end
