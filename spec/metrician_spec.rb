require "spec_helper"

RSpec.describe Metrician do
  it "has a version number" do
    Metrician::VERSION.should_not be nil
  end

  describe "database" do
    specify "ActiveRecord is instrumented" do
      Metrician.activate
      agent = Metrician.agent

      agent.stub(:gauge)
      agent.should_receive(:gauge).with("database.query", anything)

      User.where(name: "foobar").to_a
    end
  end

  describe "job systems" do
    describe "delayed_job" do
      before do
        Metrician.activate
        @agent = Metrician.agent
      end

      specify "DelayedJob is instrumented" do
        @agent.stub(:gauge)

        @agent.should_receive(:gauge).with("jobs.run", anything)
        Delayed::Job.enqueue(TestDelayedJob.new(success: true))
        Delayed::Worker.new(exit_on_complete: true).start
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)

        @agent.should_receive(:increment).with("jobs.error", 1)
        Delayed::Job.enqueue(TestDelayedJob.new(error: true))
        Delayed::Worker.new(exit_on_complete: true).start
      end

      specify "per job instrumentation" do
        Metrician.configuration[:jobs][:job_specific][:enabled] = true
        @agent.stub(:gauge)

        @agent.should_receive(:gauge).with("jobs.run.job.TestDelayedJob", anything)
        Delayed::Job.enqueue(TestDelayedJob.new(success: true))
        Delayed::Worker.new(exit_on_complete: true).start
      end
    end

    describe "resque" do
      before do
        Resque.inline = true
        Metrician.activate
        @agent = Metrician.agent
      end

      specify "Resque is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("jobs.run", anything)

        # typically Metrician would be loaded in an initalizer
        # and this _extend_ could be done inside the job itself, but here
        # we are in a weird situation.
        TestResqueJob.send(:extend, Metrician::Jobs::ResquePlugin)
        Resque.enqueue(TestResqueJob, { "success" => true })
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("jobs.error", 1)

        # typically Metrician would be loaded in an initalizer
        # and this _extend_ could be done inside the job itself, but here
        # we are in a weird situation.
        TestResqueJob.send(:extend, Metrician::Jobs::ResquePlugin)
        lambda { Resque.enqueue(TestResqueJob, { "error" => true }) }.should raise_error(StandardError)
      end
    end

    describe "sidekiq" do
      before do
        Sidekiq::Testing.inline!
        Metrician.activate
        # sidekiq doesn't use middleware by design in their testing
        # harness, so we add it just as metrician does
        # https://github.com/mperham/sidekiq/wiki/Testing#testing-server-middleware
        Sidekiq::Testing.server_middleware do |chain|
          chain.add Metrician::SidekiqMiddleware
        end
        @agent = Metrician.agent
      end

      specify "Sidekiq is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("jobs.run", anything)

        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        TestSidekiqWorker.perform_async({ "success" => true})
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("jobs.error", 1)

        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        lambda { TestSidekiqWorker.perform_async({ "error" => true}) }.should raise_error(StandardError)
      end
    end
  end

  describe "cache systems" do
    specify "redis is instrumented" do
      Metrician.activate

      client = Redis.new
      agent = Metrician.agent
      agent.stub(:gauge)
      agent.should_receive(:gauge).with("cache.command", anything)
      client.get("foo-#{rand(100_000)}")
    end

    memcached_clients = [
      defined?(::Memcached) && ::Memcached.new("localhost:11211"),
      defined?(::Dalli::Client) && ::Dalli::Client.new("localhost:11211"),
    ].compact
    raise "no memcached client" if memcached_clients.empty?

    memcached_clients.each do |client|
      specify "memcached is instrumented (#{client.class.name})" do
        Metrician.activate
        agent = Metrician.agent
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
      Metrician.activate
      agent = Metrician.agent
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
          use Metrician::RequestTiming
          use Metrician::ApplicationTiming
          run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
        end
      end

      specify "Rack timing is instrumented" do
        agent = Metrician.agent
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
          use Metrician::RequestTiming
          use Metrician::ApplicationTiming
          run lambda { |env| [500, {'Content-Type' => 'text/plain'}, ['BOOM']] }
        end
      end

      specify "500s are instrumented for error tracking" do
        agent = Metrician.agent
        agent.stub(:gauge)
        agent.stub(:increment)

        agent.should_receive(:gauge).with("web.request", anything)
        agent.should_receive(:increment).with("web.error", 1)
        get "/"
      end
    end

    describe "apdex" do
      describe "fast" do
        def app
          require "middleware/request_timing"
          require "middleware/application_timing"
          Rack::Builder.app do
            use Metrician::RequestTiming
            use Metrician::ApplicationTiming
            # This SHOULD be fast enough to fit under our
            # default threshold of 2.5s :)
            run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
          end
        end

        specify "satisfied is recorded" do
          agent = Metrician.agent
          agent.stub(:gauge)

          agent.should_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_not_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_not_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end

      end

      describe "medium" do
        def app
          require "middleware/request_timing"
          require "middleware/application_timing"
          Rack::Builder.app do
            use Metrician::RequestTiming
            use Metrician::ApplicationTiming
            run ->(env) {
              env["REQUEST_TOTAL_TIME"] = 3.0 # LOAD-BEARING
              [200, {'Content-Type' => 'text/plain'}, ['OK']]
            }
          end
        end

        specify "tolerated is recorded" do
          agent = Metrician.agent
          agent.stub(:gauge)

          agent.should_not_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_not_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end
      end

      describe "slow" do
        def app
          require "middleware/request_timing"
          require "middleware/application_timing"
          Rack::Builder.app do
            use Metrician::RequestTiming
            use Metrician::ApplicationTiming
            run ->(env) {
              env["REQUEST_TOTAL_TIME"] = 28.0 # LOAD-BEARING
              [200, {'Content-Type' => 'text/plain'}, ['OK']]
            }
          end
        end

        specify "frustrated is recorded" do
          agent = Metrician.agent
          agent.stub(:gauge)

          agent.should_not_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_not_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end
      end

    end
  end
end
