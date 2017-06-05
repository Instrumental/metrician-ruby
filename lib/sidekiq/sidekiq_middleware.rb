module Instrumental

  class SidekiqMiddleware

    def call(worker, _msg, _queue)
      start = Time.now
      yield
      InstrumentalReporters.increment("#{job_metric_instrumentation_name(worker)}.success")
    rescue
      InstrumentalReporters.increment("#{job_metric_instrumentation_name(worker)}.error")
      raise
    ensure
      duration = Time.now - start
      InstrumentalReporters.gauge(job_metric_instrumentation_name(worker), duration)
    end

  end

  def job_metric_instrumentation_name(worker)
    # remove all #, ?, !, etc. as well as runs of . and ending .'s
    name = worker.class.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    "jobs.#{name}"
  end

end
