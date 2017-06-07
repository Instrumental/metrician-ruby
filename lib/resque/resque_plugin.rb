# Reference materials:
# https://github.com/resque/resque/blob/master/docs/HOOKS.md
module Instrumental

  module ResquePlugin

    def around_perform_with_instrumental(*_args)
      start = Time.now
      yield
      InstrumentalReporters.increment("#{Instrumental::ResqueHelper.job_metric_instrumentation_name(self)}.success")
    ensure
      duration = Time.now - start
      InstrumentalReporters.gauge(Instrumental::ResqueHelper.job_metric_instrumentation_name(self), duration)
      InstrumentalReporters.agent.cleanup
    end

    def on_failure_with_instrumental(_e, *_args)
      InstrumentalReporters.increment("#{Instrumental::ResqueHelper.job_metric_instrumentation_name(self)}.error")
      InstrumentalReporters.agent.cleanup
    end

    ::Resque.before_fork = proc { InstrumentalReporters.agent.cleanup }

  end

  module ResqueHelper

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = job.to_s.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "jobs.#{name}"
    end

  end

end
