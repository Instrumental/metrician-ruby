require "instrumental/reporter"
require "instrumental_agent"
require "instrumental_reporters/railtie" if defined?(Rails)

module InstrumentalReporters

  def self.activate(api_key = nil)
    self.agent = Instrumental::Agent.new(api_key) if api_key
    Instrumental::Reporter.all.each(&:instrument)
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

  def self.dotify(klass)
    klass.to_s.underscore.gsub(%r{/}, ".")
  end

end
