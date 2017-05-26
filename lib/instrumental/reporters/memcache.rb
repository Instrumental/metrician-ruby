module Instrumental
  class Memcache < Reporter
    METHODS = [:get, :delete, :cas, :prepend, :append, :replace, :decrement, :increment, :add, :set]

    def self.memcached_gem?
      !!defined?(::Memcached)
    end

    def self.dalli_gem?
      !!defined?(::Dalli)
    end

    def client_class
      if self.class.memcached_gem?
        Memcached
      elsif self.class.dalli_gem?
        Dalli::Client
      end
    end

    def self.enabled?
      memcached_gem? || dalli_gem?
    end

    def instrument
      return if client_class.method_defined?(:get_with_instrumental_trace)
      METHODS.each do |method_name|
        next unless client_class.method_defined?(method_name)
        client_class.class_eval <<-EOD
          def #{method_name}_with_instrumental_trace(*args, &blk)
            start_time = Time.now
            begin
              #{method_name}_without_instrumental_trace(*args, &blk)
            ensure
              InstrumentalReporters.gauge("memcache.#{method_name}", (Time.now - start_time).to_f)
            end
          end
          alias #{method_name}_without_instrumental_trace #{method_name}
          alias #{method_name} #{method_name}_with_instrumental_trace
        EOD
      end
    end
  end
end
