module Metrician

  class MethodTracer < Reporter

    def self.enabled?
      true
    end

    def instrument
      Module.send(:include, TracingMethodInterceptor)
    end

  end

  module TracingMethodInterceptor

    def self.default_metric_name(klass, is_klass_method, method_name)
      name = klass.name.underscore
      name = "#{name}.self" if is_klass_method
      "tracer.#{name}.#{method_name}".downcase.tr_s("^a-zA-Z0-9.", "_")
    end

    def self.traceable_method?(klass, method_name)
      klass.method_defined?(method_name) || klass.private_method_defined?(method_name) ||
        klass.methods.include?(method_name.to_s)
    end

    def self.already_traced_method?(klass, is_klass_method, traced_name)
      is_klass_method ? klass.methods.include?(traced_name) : klass.method_defined?(traced_name)
    end

    def self.code_to_eval(is_klass_method, method_name, traced_name, untraced_name, metric_name)
      <<-EOD
        #{'class << self' if is_klass_method}
        def #{traced_name}(*args, &block)
          start_time = Time.now
          begin
            #{untraced_name}(*args, &block)
          ensure
            Metrician.gauge("#{metric_name}", (Time.now - start_time).to_f)
          end
        end
        alias :#{untraced_name} :#{method_name}
        alias :#{method_name} :#{traced_name}
        #{'end' if is_klass_method}
      EOD
    end

    def add_metrician_method_tracer(method_name, metric_name = nil)
      return false unless TracingMethodInterceptor.traceable_method?(self, method_name)

      is_klass_method = methods.include?(method_name.to_s)
      traced_name = "with_metrician_trace_#{method_name}"
      return false if TracingMethodInterceptor.already_traced_method?(self, is_klass_method, traced_name)

      metric_name ||= TracingMethodInterceptor.default_metric_name(self, is_klass_method, method_name)
      untraced_name = "without_metrician_trace_#{method_name}"

      traced_method_code =
        TracingMethodInterceptor.code_to_eval(is_klass_method, method_name, traced_name,
                                              untraced_name, metric_name)
      class_eval(traced_method_code, __FILE__, __LINE__)
    end

  end

end
