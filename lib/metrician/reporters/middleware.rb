module Metrician
  module Reporters
    class Middleware < Reporter
      def self.enabled?
        defined?(Rails) &&
          Metrician::Middleware.enabled?
      end

      def instrument
        require "metrician/middleware/request_timing"
        require "metrician/middleware/application_timing"

        app = Rails.application
        return if app.nil?

        app.middleware.insert_before(0, Metrician::Middleware::RequestTiming)
        app.middleware.insert_after(Metrician::Middleware::RequestTiming, Rack::ContentLength)
        app.middleware.use(Metrician::Middleware::ApplicationTiming)
      end
    end
  end
end
