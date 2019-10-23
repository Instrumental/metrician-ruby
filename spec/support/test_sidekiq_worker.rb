if Gemika::Env.gem?('sidekiq')
  class TestSidekiqWorker
    include Sidekiq::Worker

    def perform(options = {})
      return if options["success"]
      if options["error"]
        raise "suck it nerd"
      elsif options["exception"]
        raise Exception.new("you have poor exception handling habits")
      end
        
    end
  end
end
