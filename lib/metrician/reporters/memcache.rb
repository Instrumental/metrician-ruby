module Metrician
  class Memcache < Reporter

    METHODS = %i[get delete cas prepend append replace decrement increment add set].freeze

    def self.memcached_gem?
      !!defined?(::Memcached)
    end

    def self.dalli_gem?
      !!defined?(::Dalli) && !!defined?(::Dalli::Client)
    end

    def client_class
      if self.class.memcached_gem?
        Memcached
      elsif self.class.dalli_gem?
        Dalli::Client
      end
    end

    def self.enabled?
      (memcached_gem? || dalli_gem?) &&
        Metrician.configuration[:cache][:enabled]
    end

    def instrument
      return if client_class.method_defined?(:get_with_metrician_trace)
      METHODS.each do |method_name|
        next unless client_class.method_defined?(method_name)
        client_class.class_eval <<-RUBY
          def #{method_name}_with_metrician_trace(*args, &blk)
            start_time = Time.now
            begin
              #{method_name}_without_metrician_trace(*args, &blk)
            ensure
              duration = (Time.now - start_time).to_f
              Metrician.gauge("cache.command", duration) if Metrician.configuration[:cache][:command][:enabled]
              Metrician.gauge("cache.command.#{method_name}", duration) if Metrician.configuration[:cache][:command_specific][:enabled]
            end
          end
          alias #{method_name}_without_metrician_trace #{method_name}
          alias #{method_name} #{method_name}_with_metrician_trace
        RUBY
      end
    end

  end
end
