module Instrumental
  class DelayedJobCallbacks < ::Delayed::Plugin

    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, &block|
        begin
          start = Time.now
          block.call(job)
        ensure
          duration = Time.now - start
          InstrumentalReporters.gauge("queue.process", duration) if InstrumentalReporters.configuration[:queue][:process][:enabled]
          InstrumentalReporters.gauge("#{job_metric_instrumentation_name(worker)}.process", duration) if InstrumentalReporters.configuration[:queue][:job_specific][:enabled]
        end
      end

      lifecycle.after(:error) do |job|
        InstrumentalReporters.increment("queue.error") if InstrumentalReporters.configuration[:queue][:error][:enabled]
        InstrumentalReporters.increment("#{job_metric_instrumentation_name(worker)}.error") if InstrumentalReporters.configuration[:queue][:job_specific][:enabled]
      end
    end

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = job.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "jobs.#{name}"
    end

  end
end
