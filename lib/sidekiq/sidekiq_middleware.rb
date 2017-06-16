module Metrician
  class SidekiqMiddleware

    def call(worker, _msg, _queue)
      start = Time.now
      yield
    rescue
      Metrician.increment("queue.error") if Metrician.configuration[:queue][:error][:enabled]
      Metrician.increment("#{job_metric_instrumentation_name(worker)}.error") if Metrician.configuration[:queue][:job_specific][:enabled]
      raise
    ensure
      duration = Time.now - start
      Metrician.gauge("queue.process", duration) if Metrician.configuration[:queue][:process][:enabled]
      Metrician.gauge("#{job_metric_instrumentation_name(worker)}.process", duration) if Metrician.configuration[:queue][:job_specific][:enabled]
    end

    def job_metric_instrumentation_name(worker)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = worker.class.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "queue.#{name}"
    end

  end
end
