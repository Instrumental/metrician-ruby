require 'set'

module Instrumental
  class Reporter

    def self.all
      reporters.select(&:enabled?).map(&:new)
    end

    def self.reporters; @reporters; end

    def self.inherited(subclass)
      @reporters ||= Set.new
      @reporters  << subclass
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
require 'instrumental/reporters/honeybadger'
require 'instrumental/reporters/memcache'
require 'instrumental/reporters/method_tracer'
require 'instrumental/reporters/redis'