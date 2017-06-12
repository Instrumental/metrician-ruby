module Instrumental
  class DelayedJob < Reporter

    def self.enabled?
      !!defined?(::Delayed::Worker)
    end

    def instrument
      require "delayed_job/delayed_job_callbacks"
      ::Delayed::Worker.plugins << ::Instrumental::DelayedJobCallbacks
    end

  end
end
