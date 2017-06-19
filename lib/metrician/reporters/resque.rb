module Metrician
  class Resque < Reporter

    def self.enabled?
      !!defined?(::Resque) &&
        Metrician.configuration[:jobs][:enabled]
    end

    def instrument
      require "resque/resque_plugin"
      ::Resque::Job.send(:extend, Metrician::ResquePlugin)
    end

  end
end
