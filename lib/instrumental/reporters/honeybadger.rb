module Instrumental
  class Honeybadger < Reporter

    def self.enabled?
      !!defined?(::Honeybadger)
    end

    def instrument
      ::Honeybadger::Agent.class_eval do
        def notify_with_instrumental(exception, options = {})
          notify_without_instrumental(exception, options)
        ensure
          InstrumentalReporters.increment("exception")
          InstrumentalReporters.increment("exception.#{InstrumentalReporters.dotify(exception.class.name.underscore)}") if exception
        end
        alias_method_chain :notify, :instrumental

      end
    end

  end
end
