module Instrumental
  class Honeybadger < Reporter

    def self.enabled?
      !!defined?(::Honeybadger) &&
        InstrumentalReporters.configuration[:exception][:enabled]
    end

    def instrument
      ::Honeybadger::Agent.class_eval do
        def notify_with_instrumental(exception, options = {})
          # We can differentiate whether or not we live inside a web
          # request or not by determining the nil-ness of:
          #   context_manager.get_rack_env
          notify_without_instrumental(exception, options)
        ensure
          InstrumentalReporters.increment("exception.raise") if InstrumentalReporters.configuration[:exception][:raise][:enabled]
          InstrumentalReporters.increment("exception.raise.#{InstrumentalReporters.dotify(exception.class.name.underscore)}") if exception && InstrumentalReporters.configuration[:exception][:exception_specific][:enabled]
        end
        alias_method_chain :notify, :instrumental
      end
    end

  end
end
