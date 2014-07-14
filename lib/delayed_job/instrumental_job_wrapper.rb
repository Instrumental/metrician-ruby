class InstrumentalJobWrapper < ::Delayed::Plugin

  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, &block|
      begin
        start = Time.now
        block.call(job)
      ensure
        duration = Time.now - start
        InstrumentalReporters.agent.gauge(job_metric_instrumentation_name(job), duration)
      end
    end

    lifecycle.after(:invoke_job) do |job|
      InstrumentalReporters.agent.increment("#{job_metric_instrumentation_name(job)}.success")
    end

    lifecycle.after(:failure) do |job|
      InstrumentalReporters.agent.increment("#{job_metric_instrumentation_name(job)}.fail")
    end

    lifecycle.after(:error) do |job|
      InstrumentalReporters.agent.increment("#{job_metric_instrumentation_name(job)}.error")
    end
  end

  def self.job_metric_instrumentation_name(job)
    # remove all #, ?, !, etc. as well as runs of . and ending .'s
    name = job.name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    "jobs.#{name}"
  end

end
