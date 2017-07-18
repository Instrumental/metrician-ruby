require "metrician/configuration"
require "metrician/reporter"
require "metrician/jobs"
require "metrician/middleware"
require "instrumental_agent"
require "metrician/railtie" if defined?(Rails)

module Metrician

  def self.activate(api_key = nil)
    if api_key
      self.agent = Instrumental::Agent.new(api_key)
    end
    Metrician::Reporter.all.each(&:instrument)
  end

  def self.agent=(instrumental_agent)
    @agent = instrumental_agent
  end

  def self.agent
    @agent || null_agent
  end

  def self.null_agent
    @null_agent ||= Instrumental::Agent.new(nil, enabled: false)
  end

  def self.logger=(logger)
    agent.logger = logger
  end

  def self.logger
    agent.logger
  end

  def self.dotify(klass)
    klass.to_s.underscore.gsub(%r{/}, ".")
  end

  # TODO: consider removal/movement to Instrumental Agent
  def self.prefix=(prefix)
    @prefix = prefix.to_s[-1] == "." ? prefix.to_s : "#{prefix}."
  end

  # TODO: consider removal/movement to Instrumental Agent
  def self.prefix
    @prefix || ""
  end

  # TODO: consider removal/movement to Instrumental Agent
  def self.prefixed?
    @prefixed ||= !prefix.empty?
  end

  def self.increment(metric, value = 1)
    prefixed? ? agent.increment("#{prefix}#{metric}", value) : agent.increment(metric, value)
  end

  # TODO: add block form
  def self.gauge(metric, value)
    prefixed? ? agent.gauge("#{prefix}#{metric}", value) : agent.gauge(metric, value)
  end

  def self.configuration
    @configuration ||= Metrician::Configuration.load
  end
end
