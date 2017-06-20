# Reference materials:
# https://github.com/resque/resque/blob/master/docs/HOOKS.md
module Metrician

  module ResquePlugin

    def around_perform_with_metrician(*_args)
      start = Time.now
      yield
    ensure
      duration = Time.now - start
      Metrician.gauge("jobs.run", duration) if Metrician.configuration[:jobs][:run][:enabled]
      Metrician.gauge("jobs.run.job.#{Metrician::ResqueHelper.job_metric_instrumentation_name(self)}", duration) if Metrician.configuration[:jobs][:job_specific][:enabled]
      Metrician.agent.cleanup
    end

    def on_failure_with_metrician(_e, *_args)
      Metrician.increment("jobs.error") if Metrician.configuration[:jobs][:error][:enabled]
      Metrician.increment("jobs.error.job.#{Metrician::ResqueHelper.job_metric_instrumentation_name(self)}") if Metrician.configuration[:jobs][:job_specific][:enabled]
      Metrician.agent.cleanup
    end

    ::Resque.before_fork = proc { Metrician.agent.cleanup }

  end

  module ResqueHelper

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      job.to_s.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    end

  end

end
