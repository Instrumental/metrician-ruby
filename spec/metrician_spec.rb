require "spec_helper"
require "instrumental_agent"

module Metrician
  def self.null_agent(agent_class: Instrumental::Agent)
    self.agent = agent_class.new(nil, enabled: false)
  end
end

RSpec.describe Metrician do
  before(:each) do
    Metrician.reset
    ENV.delete("METRICIAN_CONFIG")
  end

  it "has a version number" do
    Metrician::VERSION.should_not be nil
  end

  it "can load config from ENV" do
    config = {request_timing: {enabled: "test value"}}
    t = Tempfile.new("metrician_config")
    t.write(config.to_yaml)
    t.flush
    ENV["METRICIAN_CONFIG"] = t.path
    Metrician.reset
    Metrician.configuration[:request_timing][:enabled].should == "test value"
  end

  specify "partially defined config shouldn't error" do
    t = Tempfile.new("metrician_config")
    t.write({request_timing: {enabled: true}}.to_yaml)
    t.flush
    ENV["METRICIAN_CONFIG"] = t.path
    Metrician.reset
    lambda { Metrician::Jobs.run? }.should_not raise_error
  end

  describe "Metrician.activate" do
    it "takes an agent" do
      # if this excepts, the world changed
      Metrician.activate(Metrician.null_agent)
    end

    it "excepts if the agent is nil" do
      lambda { Metrician.activate(nil) }.should raise_error(Metrician::MissingAgent)
    end

    it "excepts if the agent doesn't define one of the required agent methods" do
      class BadAgent
        # this list is from Metrician::REQUIRED_AGENT_METHODS
        def cleanup; end
        def gauge; end
        def increment; end
        def logger; end
        # def logger=(value); end
      end
      agent = BadAgent.new
      lambda { Metrician.activate(agent) }.should raise_error(Metrician::IncompatibleAgent)
    end
  end

  describe "exception tracking" do
    before do
      Metrician.configuration[:exception][:enabled] = true
      Honeybadger.configure do |config|
        config.disabled = true
      end
      @agent = Metrician.null_agent
      Metrician.activate(@agent)
    end

    describe "honeybadger" do
      specify "exceptions are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("exception.raise", 1)
        Honeybadger.notify('Something went wrong.', {
          error_class: 'MyClass',
          context: {my_data: 'value'}
        })
      end

      specify "exceptions are instrumented (job specific, string)" do
        Metrician.configuration[:exception][:exception_specific][:enabled] = true
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("exception.raise.string", 1)
        Honeybadger.notify('Something went wrong.', {
          error_class: 'MyClass',
          context: {my_data: 'value'}
        })
      end

      specify "exceptions are instrumented (job specific, exception)" do
        Metrician.configuration[:exception][:exception_specific][:enabled] = true
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("exception.raise.runtime_error", 1)
        begin
          fail 'badgers!'
        rescue => exception
          Honeybadger.notify(exception, context: {
            my_data: 'value'
          })
        end
      end
    end
  end

  describe "ActiveRecord" do
    before do
      @agent = Metrician.null_agent
      Metrician.activate(@agent)
    end

    specify "top level queries are instrumented" do
      @agent.stub(:gauge)
      @agent.should_receive(:gauge).with("database.query", anything)

      User.where(name: "foobar").to_a
    end

    specify "per command instrumentation" do
      Metrician.configuration[:database][:command][:enabled] = true
      @agent.stub(:gauge)
      @agent.should_receive(:gauge).with("database.select", anything)

      User.where(name: "foobar").to_a
    end

    specify "per table instrumentation" do
      Metrician.configuration[:database][:table][:enabled] = true
      @agent.stub(:gauge)
      @agent.should_receive(:gauge).with("database.users", anything)

      User.where(name: "foobar").to_a
    end

    specify "per command and table instrumentation" do
      Metrician.configuration[:database][:command_and_table][:enabled] = true
      @agent.stub(:gauge)
      @agent.should_receive(:gauge).with("database.select.users", anything)

      User.where(name: "foobar").to_a
    end
  end

  describe "job systems" do
    describe "delayed_job" do
      before do
        @agent = Metrician.null_agent
        Metrician.activate(@agent)
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
        @agent = Metrician.null_agent
        Metrician.activate(@agent)
      end

      after do
        Resque.inline = false
      end

      specify "Resque is instrumented" do
        @agent.stub(:gauge)
        @agent.should_receive(:gauge).with("jobs.run", anything)

        Resque::Job.create(:default, TestResqueJob, { "success" => true })
      end

      specify "job errors are instrumented" do
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("jobs.error", 1)

        lambda { Resque::Job.create(:default, TestResqueJob, { "error" => true }) }.should raise_error(StandardError)
      end
    end

    describe "sidekiq" do
      before do
        Sidekiq::Testing.inline!
        @agent = Metrician.null_agent
        Metrician.activate(@agent)
        # sidekiq doesn't use middleware by design in their testing
        # harness, so we add it just as metrician does
        # https://github.com/mperham/sidekiq/wiki/Testing#testing-server-middleware
        Sidekiq::Testing.server_middleware do |chain|
          chain.add Metrician::Jobs::SidekiqMiddleware
        end
      end

      after do
        Sidekiq::Testing.disable!
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

      specify "per job instrumentation" do
        Metrician.configuration[:jobs][:job_specific][:enabled] = true
        @agent.stub(:gauge)

        @agent.should_receive(:gauge).with("jobs.run.job.TestSidekiqWorker", anything)
        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        TestSidekiqWorker.perform_async({ "success" => true})
      end

      specify "job errors are instrumented per job" do
        Metrician.configuration[:jobs][:job_specific][:enabled] = true
        @agent.stub(:increment)
        @agent.should_receive(:increment).with("jobs.error.job.TestSidekiqWorker", 1)

        # avoid load order error of sidekiq here by just including the
        # worker bits at latest possible time
        lambda { TestSidekiqWorker.perform_async({ "error" => true}) }.should raise_error(StandardError)
      end
    end
  end

  describe "cache systems" do
    specify "redis is instrumented" do
      agent = Metrician.null_agent
      Metrician.activate(agent)
      client = Redis.new
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
        agent = Metrician.null_agent
        Metrician.activate(agent)
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
      agent = Metrician.null_agent
      Metrician.activate(agent)
      agent.stub(:gauge)

      agent.should_receive(:gauge).with("service.request", anything)
      Net::HTTP.get(URI.parse("http://example.com/"))
    end
  end

  describe "request timing" do
    include Rack::Test::Methods

    let(:agent) { Metrician.null_agent }

    describe "success case" do
      def app
        require "metrician/middleware/request_timing"
        require "metrician/middleware/application_timing"
        Rack::Builder.app do
          use Metrician::Middleware::RequestTiming
          use Metrician::Middleware::ApplicationTiming
          run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
        end
      end

      specify "Rack timing is instrumented" do
        agent.stub(:gauge)

        agent.should_receive(:gauge).with("web.request", anything)
        get "/"
      end
    end

    describe "error case" do
      def app
        require "metrician/middleware/request_timing"
        require "metrician/middleware/application_timing"
        Rack::Builder.app do
          use Metrician::Middleware::RequestTiming
          use Metrician::Middleware::ApplicationTiming
          run lambda { |env| [500, {'Content-Type' => 'text/plain'}, ['BOOM']] }
        end
      end

      specify "500s are instrumented for error tracking" do
        agent.stub(:gauge)
        agent.stub(:increment)

        agent.should_receive(:gauge).with("web.request", anything)
        agent.should_receive(:increment).with("web.error", 1)
        get "/"
      end

      specify "500s are instrumented for error tracking without request tracking" do
        Metrician.configuration[:request_timing][:request][:enabled] = false
        Metrician.configuration[:request_timing][:error][:enabled] = true
        agent.stub(:gauge)
        agent.stub(:increment)

        agent.should_not_receive(:gauge).with("web.request", anything)
        agent.should_receive(:increment).with("web.error", 1)
        get "/"
      end
    end

    describe "middleware exceptions" do
      def app
        require "metrician/middleware/request_timing"
        require "metrician/middleware/application_timing"
        Rack::Builder.app do
          use Metrician::Middleware::RequestTiming
          use Metrician::Middleware::ApplicationTiming
          run lambda { |env| raise "boom" }
        end
      end

      specify "middleware exceptions don't cause errors in response size tracking" do
        Metrician.configuration[:request_timing][:response_size][:enabled] = true
        agent.stub(:gauge)
        agent.stub(:increment)

        agent.should_receive(:gauge).with("web.request", anything)
        agent.should_receive(:increment).with("web.error", 1)
        lambda { get "/" }.should raise_error(RuntimeError, "boom")
      end
    end

    describe "queueing timing" do
      def app
        require "metrician/middleware/request_timing"
        require "metrician/middleware/application_timing"
        Rack::Builder.app do
          use Metrician::Middleware::RequestTiming
          use Metrician::Middleware::ApplicationTiming
          run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
        end
      end

      specify "Queue timing is instrumented" do
        Metrician.configuration[:request_timing][:queue_time][:enabled] = true
        agent.stub(:gauge)

        agent.should_receive(:gauge).with("web.queue_time", anything)
        get "/", {}, { Metrician::Middleware::ENV_QUEUE_START_KEYS.first => 1.second.ago.to_f }
      end
    end

    describe "apdex" do

      let(:agent) { Metrician.null_agent }

      describe "fast" do
        def app
          require "metrician/middleware/request_timing"
          require "metrician/middleware/application_timing"
          Rack::Builder.app do
            use Metrician::Middleware::RequestTiming
            use Metrician::Middleware::ApplicationTiming
            # This SHOULD be fast enough to fit under our
            # default threshold of 2.5s :)
            run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
          end
        end

        specify "satisfied is recorded" do
          agent.stub(:gauge)

          agent.should_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_not_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_not_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end

      end

      describe "medium" do
        def app
          require "metrician/middleware/request_timing"
          require "metrician/middleware/application_timing"
          Rack::Builder.app do
            use Metrician::Middleware::RequestTiming
            use Metrician::Middleware::ApplicationTiming
            run ->(env) {
              env[Metrician::Middleware::ENV_REQUEST_TOTAL_TIME] = 3.0 # LOAD-BEARING
              [200, {'Content-Type' => 'text/plain'}, ['OK']]
            }
          end
        end

        specify "tolerated is recorded" do
          agent.stub(:gauge)

          agent.should_not_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_not_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end
      end

      describe "slow" do
        def app
          require "metrician/middleware/request_timing"
          require "metrician/middleware/application_timing"
          Rack::Builder.app do
            use Metrician::Middleware::RequestTiming
            use Metrician::Middleware::ApplicationTiming
            run ->(env) {
              env[Metrician::Middleware::ENV_REQUEST_TOTAL_TIME] = 28.0 # LOAD-BEARING
              [200, {'Content-Type' => 'text/plain'}, ['OK']]
            }
          end
        end

        specify "frustrated is recorded" do
          agent.stub(:gauge)

          agent.should_not_receive(:gauge).with("web.apdex.satisfied", anything)
          agent.should_not_receive(:gauge).with("web.apdex.tolerated", anything)
          agent.should_receive(:gauge).with("web.apdex.frustrated", anything)
          get "/"
        end
      end

    end

    describe "rails" do
      def app
        Rails.application
      end

      let(:agent) { Metrician.null_agent }

      before do
        Metrician.activate(agent)
      end

      it "hooks into rails automatically" do
        agent.stub(:gauge)
        agent.should_receive(:gauge).with("web.request", anything)

        get "/"
        last_response.body.should == "foobar response"
      end
    end
  end
end
