require "spec_helper"

RSpec.describe InstrumentalReporters do
  it "has a version number" do
    InstrumentalReporters::VERSION.should_not be nil
  end

  describe "database" do
    specify "ActiveRecord is instrumented" do
      InstrumentalReporters.activate
      agent = InstrumentalReporters.agent

      agent.stub(:gauge)
      agent.should_receive(:gauge).with("database.query", anything)

      User.where(name: "foobar").to_a
    end
  end

  describe "job queue systems" do
    specify "DelayedJob is instrumented" do
      require "delayed_job_active_record"
      InstrumentalReporters.activate
      agent = InstrumentalReporters.agent

      agent.stub(:gauge)
      agent.should_receive(:gauge).with("queue.process", anything)

      Delayed::Job.enqueue(TestDelayedJob.new(success: true))
      Delayed::Worker.new(exit_on_complete: true).start
    end

    specify "Resque is instrumented" do
      require "resque"
      Resque.inline = true
      InstrumentalReporters.activate
      agent = InstrumentalReporters.agent

      agent.stub(:gauge)
      agent.should_receive(:gauge).with("queue.process", anything)

      # typically instrumental reporters would be loaded in an initalizer
      # and this _extend_ could be done inside the job itself, but here
      # we are in a weird situation.
      TestResqueJob.send(:extend, Instrumental::ResquePlugin)
      Resque.enqueue(TestResqueJob, { "success" => true })
    end

    specify "Sidekiq is instrumented" do
      require "sidekiq"
      require 'sidekiq/testing'
      Sidekiq::Testing.inline!
      InstrumentalReporters.activate
      # sidekiq doesn't use middleware by default in their testing
      # harness, so we add it just as metrician does
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Instrumental::SidekiqMiddleware
      end
      agent = InstrumentalReporters.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("queue.process", anything)

      # avoid load order error of sidekiq here by just including the
      # worker bits at latest possible time
      TestSidekiqWorker.send(:include, Sidekiq::Worker)
      TestSidekiqWorker.perform_async({ "success" => true})
    end
  end

  describe "cache systems" do
    specify "redis is instrumented" do
      require "redis"
      InstrumentalReporters.activate

      client = Redis.new
      agent = InstrumentalReporters.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("cache.command", anything)
      client.get("foo")
    end

    # Why is this fuckshow? In Rails 4x, we're going to load the
    # memcached gem, and in 5 we're going to use dalli
    # this will allow us to set up a client without blowing up
    # in the wrong env.
    def memcached_client
      begin
        require "memcached"
        return Memcached.new("localhost:11211")
      rescue LoadError
      end
      begin
        require "dalli"
        return Dalli::Client.new("localhost:11211")
      rescue LoadError
      end
      raise "no memcached client"
    end

    specify "memcached is instrumented" do
      client = memcached_client
      InstrumentalReporters.activate

      agent = InstrumentalReporters.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("cache.command", anything)
      begin
        client.get("foo-#{rand(100_000)}")
      rescue Memcached::NotFound
        # memcached raises this when there is no value for "foo-N" set
      end
    end
  end

  describe "external service timing" do
    specify "Net::HTTP is instrumented" do
      InstrumentalReporters.activate

      agent = InstrumentalReporters.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("service.request", anything)
      Net::HTTP.get(URI.parse("http://example.com/"))
    end
  end
end
