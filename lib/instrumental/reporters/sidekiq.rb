module Instrumental
  class Sidekiq < Reporter

    def self.enabled?
      !!defined?(::Sidekiq)
    end

    def instrument
      require "sidekiq/sidekiq_middleware"
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Sidekiq::Middleware::Server::Logging, Instrumental::SidekiqMiddleware
        end
      end
    end

  end
end
