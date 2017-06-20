module Metrician
  class DelayedJobCallbacks < ::Delayed::Plugin

    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, &block|
        begin
          start = Time.now
          block.call(job)
        ensure
          duration = Time.now - start
          Metrician.gauge("jobs.run", duration) if Metrician.configuration[:jobs][:run][:enabled]
          Metrician.gauge("jobs.task.#{job_metric_instrumentation_name(job)}", duration) if Metrician.configuration[:jobs][:job_specific][:enabled]
        end
      end

      lifecycle.after(:error) do |job|
        Metrician.increment("jobs.error") if Metrician.configuration[:jobs][:error][:enabled]
        Metrician.increment("jobs.error.task.#{job_metric_instrumentation_name(job)}") if Metrician.configuration[:jobs][:job_specific][:enabled]
      end
    end

    def self.job_metric_instrumentation_name(job)
      # remove all #, ?, !, etc. as well as runs of . and ending .'s
      job.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    end

  end
end
