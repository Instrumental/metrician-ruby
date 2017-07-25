# Reference materials:
# https://github.com/resque/resque/blob/master/docs/HOOKS.md
module Metrician
  module Jobs
    module ResquePlugin
      module Extension
        def around_perform_with_metrician(*_args)
          start = Time.now
          yield
        ensure
          if Jobs.run?
            duration = Time.now - start
            Metrician.gauge(Jobs::RUN_METRIC, duration)
            if Jobs.job_specific?
              Metrician.gauge("#{Jobs::RUN_METRIC}.job.#{Jobs.instrumentation_name(self.to_s)}", duration)
            end
            Metrician.agent.cleanup
          end
        end

        def on_failure_with_metrician(_e, *_args)
          if Jobs.error?
            Metrician.increment(Jobs::ERROR_METRIC)
            if Jobs.job_specific?
              Metrician.increment("#{Jobs::ERROR_METRIC}.job.#{Jobs.instrumentation_name(self.to_s)}")
            end
            Metrician.agent.cleanup
          end
        end

        ::Resque.before_fork = proc { Metrician.agent.cleanup }
      end

      module Installer
        def self.included(base)
          base.send(:alias_method, :payload_class_without_metrician, :payload_class)
          base.send(:alias_method, :payload_class, :payload_class_with_metrician)
        end

        def payload_class_with_metrician
          payload_class_without_metrician.tap do |klass|
            unless klass.respond_to?(:around_perform_with_metrician)
              klass.instance_eval do
                extend(::Metrician::Jobs::ResquePlugin::Extension)
              end
            end
          end
        end
      end
    end
  end
end
