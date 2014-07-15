module InstrumentalRails
  class Railtie < Rails::Railtie

    initializer "instrumental_rails.load_middleware" do |app|
      app.middleware.insert_before("ActionDispatch::Static", "RequestTiming")
      app.middleware.insert_before("ActionDispatch::Static", "Rack::ContentLength")
      app.middleware.use("ApplicationTiming")
    end

  end
end
