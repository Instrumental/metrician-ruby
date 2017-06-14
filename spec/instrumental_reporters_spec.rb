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
    describe "delayed_job" do
      before do
        InstrumentalReporters.activate
        @agent = InstrumentalReporters.agent
      end

      specify "DelayedJob is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("queue.process", anything)

        Delayed::Job.enqueue(TestDelayedJob.new(success: true))
        Delayed::Worker.new(exit_on_complete: true).start
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("queue.error", 1)

        Delayed::Job.enqueue(TestDelayedJob.new(error: true))
        Delayed::Worker.new(exit_on_complete: true).start
      end
    end

    describe "resque" do
      before do
        Resque.inline = true
        InstrumentalReporters.activate
        @agent = InstrumentalReporters.agent
      end

      specify "Resque is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("queue.process", anything)

        # typically instrumental reporters would be loaded in an initalizer
        # and this _extend_ could be done inside the job itself, but here
        # we are in a weird situation.
        TestResqueJob.send(:extend, Instrumental::ResquePlugin)
        Resque.enqueue(TestResqueJob, { "success" => true })
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("queue.error", 1)

        # typically instrumental reporters would be loaded in an initalizer
        # and this _extend_ could be done inside the job itself, but here
        # we are in a weird situation.
        TestResqueJob.send(:extend, Instrumental::ResquePlugin)
        lambda { Resque.enqueue(TestResqueJob, { "error" => true }) }.should raise_error(StandardError)
      end
    end

    describe "sidekiq" do
      before do
        Sidekiq::Testing.inline!
        InstrumentalReporters.activate
        # sidekiq doesn't use middleware by design in their testing
        # harness, so we add it just as metrician does
        # https://github.com/mperham/sidekiq/wiki/Testing#testing-server-middleware
        Sidekiq::Testing.server_middleware do |chain|
          chain.add Instrumental::SidekiqMiddleware
        end
        @agent = InstrumentalReporters.agent
      end

      specify "Sidekiq is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("queue.process", anything)

        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        TestSidekiqWorker.perform_async({ "success" => true})
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("queue.error", 1)

        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        lambda { TestSidekiqWorker.perform_async({ "error" => true}) }.should raise_error(StandardError)
      end
    end
  end

  describe "cache systems" do
    specify "redis is instrumented" do
      InstrumentalReporters.activate

      client = Redis.new
      agent = InstrumentalReporters.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("cache.command", anything)
      client.get("foo-#{rand(100_000)}")
    end

    [
      defined?(::Memcached) && ::Memcached.new("localhost:11211"),
      defined?(::Dalli::Client) && ::Dalli::Client.new("localhost:11211"),
    ].compact.each do |client|
      specify "memcached is instrumented" do
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

  describe "request timing" do
    include Rack::Test::Methods

    describe "success case" do
      def app
        require "middleware/request_timing"
        require "middleware/application_timing"
        Rack::Builder.app do
          use Instrumental::RequestTiming
          use Instrumental::ApplicationTiming
          run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
        end
      end

      specify "Rack timing is instrumented" do
        agent = InstrumentalReporters.agent
        agent.stub(:gauge)
        agent.should_receive(:gauge).with("web.request", anything)

        get "/"
      end
    end

    describe "error case" do
      def app
        require "middleware/request_timing"
        require "middleware/application_timing"
        Rack::Builder.app do
          use Instrumental::RequestTiming
          use Instrumental::ApplicationTiming
          run lambda { |env| [500, {'Content-Type' => 'text/plain'}, ['BOOM']] }
        end
      end

      specify "500s are instrumented for error tracking" do
        agent = InstrumentalReporters.agent
        agent.stub(:gauge)
        agent.stub(:increment)
        agent.should_receive(:gauge).with("web.request", anything)
        agent.should_receive(:increment).with("web.error", 1)

        get "/"
      end
    end
  end
end
