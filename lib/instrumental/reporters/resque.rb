module Instrumental
  class Resque < Reporter

    def self.enabled?
      !!defined?(::Resque) &&
        InstrumentalReporters.configuration[:queue][:enabled]
    end

    def instrument
      require "resque/resque_plugin"
      ::Resque::Job.send(:extend, Instrumental::ResquePlugin)
    end

  end
end
