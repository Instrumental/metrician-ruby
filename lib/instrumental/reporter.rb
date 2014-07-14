module Instrumental
  class Reporter

    def self.all
      constants.map    { |class_sym| const_get(class_sym) }
               .select { |klass|     klass.is_a?(Instrumental::Reporter) }
               .select (&:enabled?)
               .map    (&:new)
    end

    def self.enabled?
      false
    end

    def instrument
      nil
    end

  end
end

require 'instrumental/reporters/database'
require 'instrumental/reporters/delayed_job'
require 'instrumental/reporters/memcache'
require 'instrumental/reporters/method_tracer'
require 'instrumental/reporters/redis'
