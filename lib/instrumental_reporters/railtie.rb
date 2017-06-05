module InstrumentalReporters
  class Railtie < Rails::Railtie

    initializer "instrumental_rails.load_middleware" do |app|
      require "middleware/request_timing"
      require "middleware/application_timing"

      # TODO: namespace the request and application timing bits
      # TODO check if raw module names work in rails < 5, and split logic here if not
      app.middleware.insert_before(0, RequestTiming)
      app.middleware.insert_after(RequestTiming, Rack::ContentLength)
      app.middleware.use(ApplicationTiming)
    end

  end
end
