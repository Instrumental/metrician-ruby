require 'instrumental/reporter'

module InstrumentalRails

  def self.activate_instrumentation
    Instrumental::Reporter.all.each(&:instrument)
  end

end
