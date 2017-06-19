module Metrician
  class Sidekiq < Reporter

    def self.enabled?
      !!defined?(::Sidekiq) &&
        Metrician.configuration[:jobs][:enabled]
    end

    def instrument
      require "sidekiq/sidekiq_middleware"
      ::Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Metrician::SidekiqMiddleware
        end
      end
    end

  end
end
