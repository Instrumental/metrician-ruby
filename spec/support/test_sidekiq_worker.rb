if Gemika::Env.gem?('sidekiq')
  class TestSidekiqWorker
    include Sidekiq::Worker

    def perform(options = {})
      return if options["success"]
      if options["error"]
        raise "A StandardError asks his boss for a raise."
      elsif options["exception"]
        raise Exception.new("The boss says no, you have poor exception handling habits")
      end
        
    end
  end
end
