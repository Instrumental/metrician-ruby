module Metrician
  class Resque < Reporter

    def self.enabled?
      !!defined?(::Resque) &&
        Metrician::Jobs.enabled?
    end

    def instrument
      require "metrician/jobs/resque_plugin"
      unless ::Resque::Job.method_defined?(:payload_class_with_metrician)
        ::Resque::Job.send(:include, Metrician::Jobs::ResquePlugin::Installer)
      end
    end

  end
end
