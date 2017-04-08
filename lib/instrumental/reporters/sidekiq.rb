module Instrumental
  class Sidekiq < Reporter
    def self.enabled?
      !!defined?(::Sidekiq)
    end

    def instrument
      require "sidekiq/instrumental_job_wrapper"
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.insert_before Sidekiq::Middleware::Server::Logging, Instrumental::SidekiqMiddleware
        end
      end
    end
  end
end
