module Metrician
  module Jobs

    RUN_METRIC   = "jobs.run".freeze
    ERROR_METRIC = "jobs.error".freeze

    def self.configuration
      @configuration ||= Metrician.configuration[:jobs]
    end

    def self.enabled?
      @enabled ||= configuration[:enabled]
    end

    def self.run?
      @run ||= configuration[:run][:enabled]
    end

    def self.error?
      @error ||= configuration[:error][:enabled]
    end

    def self.job_specific?
      @job_specific ||= configuration[:job_specific][:enabled]
    end

    def self.instrumentation_name(job_name)
      job_name.gsub(/[^\w]+/, ".").gsub(/\.+$/, "")
    end

    def self.reset
      %i[@configuration @enabled @run @error @job_specific].each do |memo_ivar|
        if instance_variable_defined?(memo_ivar)
          remove_instance_variable(memo_ivar)
        end
      end
    end

  end
end
