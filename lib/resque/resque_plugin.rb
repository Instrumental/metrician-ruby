module Instrumental
  module ResquePlugin
    def around_perform_with_instrumental(*args)
      start = Time.now
      yield
      InstrumentalReporters.agent.increment("#{Instrumental::ResqueHelper.job_metric_instrumentation_name(self)}.success")
    ensure
      InstrumentalReporters.agent.gauge(Instrumental::ResqueHelper.job_metric_instrumentation_name(self))
    end

    def on_failure_with_instrumental(e, *args)
      InstrumentalReporters.agent.increment("#{Instrumental::ResqueHelper.job_metric_instrumentation_name(self)}.error")
    end
  end

  module ResqueHelper
    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = job.to_s.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "jobs.#{name}"
    end
  end
end
