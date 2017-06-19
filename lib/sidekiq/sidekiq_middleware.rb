module Metrician
  class SidekiqMiddleware

    def call(worker, _msg, _queue)
      start = Time.now
      yield
    rescue
      Metrician.increment("jobs.error") if Metrician.configuration[:jobs][:error][:enabled]
      Metrician.increment("jobs.error.#{job_metric_instrumentation_name(worker)}") if Metrician.configuration[:jobs][:job_specific][:enabled]
      raise
    ensure
      duration = Time.now - start
      Metrician.gauge("jobs.run", duration) if Metrician.configuration[:jobs][:run][:enabled]
      Metrician.gauge("jobs.run.#{job_metric_instrumentation_name(worker)}", duration) if Metrician.configuration[:jobs][:job_specific][:enabled]
    end

    def job_metric_instrumentation_name(worker)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      worker.class.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    end

  end
end
