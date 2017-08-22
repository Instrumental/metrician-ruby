module Metrician

  class MethodTimer < Reporter

    def self.enabled?
      Metrician.configuration[:method_timer][:enabled]
    end

    def instrument
      Module.send(:include, TimingMethodInterceptor)
    end

  end

  module TimingMethodInterceptor

    def self.default_metric_name(klass, is_klass_method, method_name)
      name = klass.name.underscore
      name = "#{name}.self" if is_klass_method
      "timer.#{name}.#{method_name}".downcase.tr_s("^a-zA-Z0-9.", "_")
    end

    def self.timeable_method?(klass, method_name)
      klass.method_defined?(method_name) ||
        klass.private_method_defined?(method_name) ||
        klass.methods.include?(method_name)
    end

    def self.already_timed_method?(klass, is_klass_method, timed_name)
      is_klass_method ?
        klass.methods.include?(timed_name) :
        klass.method_defined?(timed_name)
    end

    def self.code_to_eval(is_klass_method, method_name, timed_name, untimed_name, metric_name)
      <<-EOD
        #{'class << self' if is_klass_method}
        def #{timed_name}(*args, &block)
          start_time = Time.now
          begin
            #{untimed_name}(*args, &block)
          ensure
            Metrician.gauge("#{metric_name}", (Time.now - start_time).to_f)
          end
        end
        alias :#{untimed_name} :#{method_name}
        alias :#{method_name} :#{timed_name}
        #{'end' if is_klass_method}
      EOD
    end

    def add_metrician_method_timer(method_name, metric_name = nil)
      return false unless TimingMethodInterceptor.timeable_method?(self, method_name)

      is_klass_method = methods.include?(method_name)
      timed_name = "with_metrician_time_#{method_name}"
      return false if TimingMethodInterceptor.already_timed_method?(self, is_klass_method, timed_name)

      metric_name ||= TimingMethodInterceptor.default_metric_name(self, is_klass_method, method_name)
      untimed_name = "without_metrician_time_#{method_name}"

      timed_method_code =
        TimingMethodInterceptor.code_to_eval(is_klass_method, method_name, timed_name,
                                              untimed_name, metric_name)
      class_eval(timed_method_code, __FILE__, __LINE__)
    end

  end

end
