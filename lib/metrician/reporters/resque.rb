module Metrician
  class Resque < Reporter

    def self.enabled?
      !!defined?(::Resque) &&
        Metrician::Jobs.enabled?
    end

    def instrument
      require "metrician/jobs/resque_plugin"
      unless ::Resque::Job.respond_to?(:around_perform_with_metrician)
        ::Resque::Job.send(:extend, Metrician::Jobs::ResquePlugin)
      end
    end

  end
end
