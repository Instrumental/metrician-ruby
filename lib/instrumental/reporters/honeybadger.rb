module Instrumental
  class Honeybadger < Reporter

    def self.enabled?
      !!defined?(::Honeybadger)
    end

    def instrument
      ::Honeybadger.class_eval do
        class << self

          def notify_with_instrumental(exception, options = {})
            notify_without_instrumental(exception, options)
            InstrumentalReporters.agent.increment("exception")
            InstrumentalReporters.agent.increment("exception.#{InstrumentalReporters.dotify(exception.class.name.underscore)}") if exception
          end
          alias_method_chain :notify, :instrumental

          def notify_or_ignore_with_instrumental(exception, options = {})
            notify_or_ignore_without_instrumental(exception, options)
            InstrumentalReporters.agent.increment("exception")
            InstrumentalReporters.agent.increment("exception.#{InstrumentalReporters.dotify(exception.class.name.underscore)}") if exception
          end
          alias_method_chain :notify_or_ignore, :instrumental

        end
      end
    end

  end
end
