module InstrumentalReporters
  class Railtie < Rails::Railtie

    initializer "instrumental_reporters.load_middleware" do |app|
      require "middleware/request_timing"
      require "middleware/application_timing"

      app.middleware.insert_before(0, Instrumental::RequestTiming)
      app.middleware.insert_after(Instrumental::RequestTiming, Rack::ContentLength)
      app.middleware.use(Instrumental::ApplicationTiming)
    end

  end
end
