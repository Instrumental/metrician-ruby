if Gemika::Env.gem?('sidekiq')
  class TestSidekiqWorker
    include Sidekiq::Worker

    def perform(options = {})
      return if options["success"]
      raise "suck it nerd" if options["error"]
    end
  end
end
