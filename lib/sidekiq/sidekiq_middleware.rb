module Instrumental
  class SidekiqMiddleware

    def call(worker, _msg, _queue)
      start = Time.now
      yield
    rescue
      InstrumentalReporters.increment("queue.error") if InstrumentalReporters.configuration[:queue][:error][:enabled]
      InstrumentalReporters.increment("#{job_metric_instrumentation_name(worker)}.error") if InstrumentalReporters.configuration[:queue][:job_specific][:enabled]
      raise
    ensure
      duration = Time.now - start
      InstrumentalReporters.gauge("queue.process", duration) if InstrumentalReporters.configuration[:queue][:process][:enabled]
      InstrumentalReporters.gauge("#{job_metric_instrumentation_name(worker)}.process", duration) if InstrumentalReporters.configuration[:queue][:job_specific][:enabled]
    end

    def job_metric_instrumentation_name(worker)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = worker.class.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "queue.#{name}"
    end

  end
end
