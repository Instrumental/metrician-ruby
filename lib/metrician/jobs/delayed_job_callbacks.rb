module Metrician
  module Jobs
    class DelayedJobCallbacks < ::Delayed::Plugin

      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, &block|
          begin
            start = Time.now
            block.call(job)
          ensure
            if Jobs.run?
              duration = Time.now - start
              Metrician.gauge(Jobs::RUN_METRIC, duration)
              if Jobs.job_specific?
                Metrician.gauge("#{Jobs::RUN_METRIC}.job.#{Jobs.instrumentation_name(job.name)}", duration)
              end
            end
          end
        end

        lifecycle.after(:error) do |_worker, job|
          if Jobs.error?
            Metrician.increment(Jobs::ERROR_METRIC)
            if Jobs.job_specific?
              Metrician.increment("#{Jobs::ERROR_METRIC}.job.#{Jobs.instrumentation_name(job.name)}")
            end
          end
        end
      end

    end
  end
end
