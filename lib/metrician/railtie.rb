module Metrician
  class Railtie < Rails::Railtie

    initializer "metrician.load_middleware" do |app|
      next unless Metrician.configuration[:request_timing][:enabled]

      require "middleware/request_timing"
      require "middleware/application_timing"

      app.middleware.insert_before(0, Metrician::RequestTiming)
      app.middleware.insert_after(Metrician::RequestTiming, Rack::ContentLength)
      app.middleware.use(Metrician::ApplicationTiming)
    end

  end
end
