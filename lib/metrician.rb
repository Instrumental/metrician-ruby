require "English"
require "metrician/configuration"
require "metrician/reporter"
require "metrician/jobs"
require "metrician/middleware"

module Metrician

  AgentNotInitialized = Class.new(StandardError)
  MissingAgent = Class.new(ArgumentError)
  IncompatibleAgent = Class.new(ArgumentError)

  REQUIRED_AGENT_METHODS = [
    :cleanup,
    :gauge,
    :increment,
    :logger,
    "logger=".to_sym,
  ]

  def self.activate(agent)
    self.agent = agent
    Metrician::Reporter.all.each(&:instrument)
  end

  def self.agent=(agent)
    if agent.nil?
      raise MissingAgent.new
    end

    REQUIRED_AGENT_METHODS.each do |method|
      raise IncompatibleAgent.new("agent must implement #{method}") unless agent.respond_to?(method)
    end

    @agent = agent
  end

  def self.agent
    @agent || raise(AgentNotInitialized.new)
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

  def self.reset
    %i[@agent @configuration].each do |memo_ivar|
      if Metrician.instance_variable_defined?(memo_ivar)
        Metrician.remove_instance_variable(memo_ivar)
      end
    end
  end
end
