module Metrician
  class Honeybadger < Reporter

    EXCEPTION_METRIC = "tracked_exception"

    def self.enabled?
      !!defined?(::Honeybadger) &&
        Metrician.configuration[:exception][:enabled]
    end

    def instrument
      return if ::Honeybadger::Agent.method_defined?(:notify_with_metrician)
      ::Honeybadger::Agent.class_eval do
        def notify_with_metrician(exception, options = {})
          # We can differentiate whether or not we live inside a web
          # request or not by determining the nil-ness of:
          #   context_manager.get_rack_env
          notify_without_metrician(exception, options)
        ensure
          Metrician.increment(EXCEPTION_METRIC) if Metrician.configuration[:exception][:raise][:enabled]
          # TODO: underscore is rails only
          Metrician.increment("#{EXCEPTION_METRIC}.#{Metrician.dotify(exception.class.name.underscore)}") if exception && Metrician.configuration[:exception][:exception_specific][:enabled]
        end
        alias_method :notify_without_metrician, :notify
        alias_method :notify, :notify_with_metrician
      end
    end

  end
end
