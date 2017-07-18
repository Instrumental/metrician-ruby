module Metrician
  class Railtie < Rails::Railtie

    initializer "metrician.load_rack_middleware" do |app|
      next unless Metrician::Middleware.enabled? #configuration[:request_timing][:enabled]

      require "metrician/middleware/request_timing"
      require "metrician/middleware/application_timing"

      app.middleware.insert_before(0, Metrician::Middleware::RequestTiming)
      app.middleware.insert_after(Metrician::Middleware::RequestTiming, Rack::ContentLength)
      app.middleware.use(Metrician::Middleware::ApplicationTiming)
    end

  end
end
