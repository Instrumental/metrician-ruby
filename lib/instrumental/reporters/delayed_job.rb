module Instrumental

  class DelayedJob < Reporter
    def self.enabled?
      defined?(::Delayed::Worker)
    end

    def instrument
      require 'delayed_job/instrumental_job_wrapper'
      ::Delayed::Worker.plugins << InstrumentalJobWrapper
    end
  end

end
