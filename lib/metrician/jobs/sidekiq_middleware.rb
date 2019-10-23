module Metrician
  module Jobs
    class SidekiqMiddleware

      def call(worker, _msg, _queue)
        start = Time.now
        yield
      rescue Exception => e
        if Jobs.error?
          Metrician.increment(Jobs::ERROR_METRIC)
          if Jobs.job_specific?
            Metrician.increment("#{Jobs::ERROR_METRIC}.job.#{Jobs.instrumentation_name(worker.class.name)}")
          end
        end
        raise
      ensure
        if Jobs.run?
          duration = Time.now - start
          Metrician.gauge(Jobs::RUN_METRIC, duration)
          if Jobs.job_specific?
            Metrician.gauge("#{Jobs::RUN_METRIC}.job.#{Jobs.instrumentation_name(worker.class.name)}", duration)
          end
        end
      end

    end
  end
end
