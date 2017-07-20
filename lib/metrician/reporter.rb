require "set"

module Metrician
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

require "metrician/reporters/active_record"
require "metrician/reporters/delayed_job"
require "metrician/reporters/honeybadger"
require "metrician/reporters/memcache"
require "metrician/reporters/method_tracer"
require "metrician/reporters/middleware"
require "metrician/reporters/net_http"
require "metrician/reporters/redis"
require "metrician/reporters/resque"
require "metrician/reporters/sidekiq"
