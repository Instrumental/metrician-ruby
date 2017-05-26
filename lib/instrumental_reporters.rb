require 'instrumental/reporter'
require 'instrumental_agent'

require 'instrumental_reporters/railtie' if defined?(Rails)

module InstrumentalReporters

  def self.activate(api_key = nil)
    if api_key
      self.agent = Instrumental::Agent.new(api_key)
    end
    Instrumental::Reporter.all.each(&:instrument)
  end

  def self.agent=(instrumental_agent)
    @agent = instrumental_agent
  end

  def self.agent
    @agent || null_agent
  end

  def self.null_agent
    @null_agent ||= Instrumental::Agent.new(nil, :enabled => false)
  end

  def self.dotify(klass)
    klass.to_s.underscore.gsub(/\//, '.')
  end

  def self.prefix=(prefix)
    @prefix = prefix.to_s[-1] == "." ? prefix.to_s : "#{prefix}."
  end

  def self.prefix
    @prefix || ""
  end

  def self.prefixed?
    @prefixed ||= prefix.empty?
  end

  def self.increment(metrics, value)
    prefixed? ?
      agent.increment("#{prefix}#{metric}", value) :
      agent.increment(metric, value)
  end

  def self.gauge(metric, value)
    prefixed? ?
      agent.gauge("#{prefix}#{metric}", value) :
      agent.gauge(metric, value)
  end
end
