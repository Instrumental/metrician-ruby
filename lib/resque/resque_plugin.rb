# Reference materials:
# https://github.com/resque/resque/blob/master/docs/HOOKS.md
module Metrician

  module ResquePlugin

    def around_perform_with_metrician(*_args)
      start = Time.now
      yield
    ensure
      duration = Time.now - start
      Metrician.gauge("queue.process", duration) if Metrician.configuration[:queue][:process][:enabled]
      Metrician.gauge("#{Metrician::ResqueHelper.job_metric_instrumentation_name(self)}.process", duration) if Metrician.configuration[:queue][:job_specific][:enabled]
      Metrician.agent.cleanup
    end

    def on_failure_with_metrician(_e, *_args)
      Metrician.increment("queue.error") if Metrician.configuration[:queue][:error][:enabled]
      Metrician.increment("#{Metrician::ResqueHelper.job_metric_instrumentation_name(self)}.error") if Metrician.configuration[:queue][:job_specific][:enabled]
      Metrician.agent.cleanup
    end

    ::Resque.before_fork = proc { Metrician.agent.cleanup }

  end

  module ResqueHelper

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = job.to_s.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "queue.#{name}"
    end

  end

end
