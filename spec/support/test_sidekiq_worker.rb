class TestSidekiqWorker

  def perform(options = {})
    return if options["success"]
    raise "suck it nerd" if options["error"]
  end
end
