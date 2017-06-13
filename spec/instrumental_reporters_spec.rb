require "spec_helper"

RSpec.describe InstrumentalReporters do
  it "has a version number" do
    InstrumentalReporters::VERSION.should_not be nil
  end

  specify "ActiveRecord is instrumented" do
    InstrumentalReporters.activate
    agent = InstrumentalReporters.agent

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("database.query", anything)

    User.where(name: "foobar").to_a
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
end
