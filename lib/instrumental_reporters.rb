require 'instrumental/reporter'
require 'instrumental_agent'

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

  def self.agent; @agent; end

end
