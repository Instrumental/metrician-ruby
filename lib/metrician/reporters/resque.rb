module Metrician
  class Resque < Reporter

    def self.enabled?
      !!defined?(::Resque) &&
        Metrician::Jobs.enabled?
    end

    def instrument
      require "metrician/jobs/resque_plugin"
      ::Resque::Job.send(:extend, Metrician::Jobs::ResquePlugin)
    end

  end
end
