module Metrician
  class DelayedJob < Reporter

    def self.enabled?
      !!defined?(::Delayed::Worker) &&
        Metrician::Jobs.enabled?
    end

    def instrument
      require "metrician/jobs/delayed_job_callbacks"
      unless ::Delayed::Worker.plugins.include?(::Metrician::Jobs::DelayedJobCallbacks)
        ::Delayed::Worker.plugins << ::Metrician::Jobs::DelayedJobCallbacks
      end
    end

  end
end
