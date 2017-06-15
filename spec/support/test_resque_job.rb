class TestResqueJob
  @queue = :default

  def self.perform(options)
    return if options["success"]
    raise "Test explosion: PC LOAD LETTER" if options["error"]
  end
end
