module Metrician
  class DelayedJobCallbacks < ::Delayed::Plugin

    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, &block|
        begin
          start = Time.now
          block.call(job)
        ensure
          duration = Time.now - start
          Metrician.gauge("queue.process", duration) if Metrician.configuration[:queue][:process][:enabled]
          Metrician.gauge("#{job_metric_instrumentation_name(worker)}.process", duration) if Metrician.configuration[:queue][:job_specific][:enabled]
        end
      end

      lifecycle.after(:error) do |job|
        Metrician.increment("queue.error") if Metrician.configuration[:queue][:error][:enabled]
        Metrician.increment("#{job_metric_instrumentation_name(worker)}.error") if Metrician.configuration[:queue][:job_specific][:enabled]
      end
    end

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      name = job.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
      "jobs.#{name}"
    end

  end
end
