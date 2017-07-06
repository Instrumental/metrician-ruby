module Metrician
  class Sidekiq < Reporter

    def self.enabled?
      !!defined?(::Sidekiq) &&
        Metrician::Jobs.enabled?
    end

    def instrument
      require "metrician/jobs/sidekiq_middleware"
      ::Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add ::Metrician::Jobs::SidekiqMiddleware
        end
      end
    end

  end
end
