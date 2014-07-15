module InstrumentalReporters
  class Railtie < Rails::Railtie

    initializer "instrumental_rails.load_middleware" do |app|
      require 'middleware/request_timing'
      require 'middleware/application_timing'

      app.middleware.insert_before("ActionDispatch::Static", "RequestTiming")
      app.middleware.insert_before("ActionDispatch::Static", "Rack::ContentLength")
      app.middleware.use("ApplicationTiming")
    end

  end
end
