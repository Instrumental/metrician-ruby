module Metrician
  class DelayedJob < Reporter

    def self.enabled?
      !!defined?(::Delayed::Worker) &&
        Metrician.configuration[:queue][:enabled]
    end

    def instrument
      require "delayed_job/delayed_job_callbacks"
      ::Delayed::Worker.plugins << ::Metrician::DelayedJobCallbacks
    end

  end
end
