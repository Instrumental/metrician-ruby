require "set"

module Instrumental
  class Reporter

    def self.all
      reporters.select(&:enabled?).map(&:new)
    end

    class << self

      attr_reader :reporters

    end

    def self.inherited(subclass)
      @reporters ||= Set.new
      @reporters << subclass
    end

    def self.enabled?
      false
    end

    def instrument
      nil
    end

  end
end

require "instrumental/reporters/database"
require "instrumental/reporters/delayed_job"
require "instrumental/reporters/honeybadger"
require "instrumental/reporters/memcache"
require "instrumental/reporters/method_tracer"
require "instrumental/reporters/net_http"
require "instrumental/reporters/redis"
require "instrumental/reporters/resque"
require "instrumental/reporters/sidekiq"
