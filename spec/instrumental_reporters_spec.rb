require "spec_helper"

RSpec.describe InstrumentalReporters do
  it "has a version number" do
    InstrumentalReporters::VERSION.should_not be nil
  end

  it "ActiveRecord is instrumented" do
    Instrumental::Agent.logger = Logger.new(StringIO.new(""))
    agent = Instrumental::Agent.new("test api token")
    InstrumentalReporters.agent = agent
    InstrumentalReporters.activate

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("database.query", anything)

    User.where(name: "foobar").to_a
  end

  it "DelayedJob is instrumented" do
    require "delayed_job_active_record"
    Instrumental::Agent.logger = Logger.new(StringIO.new(""))
    agent = Instrumental::Agent.new("test api token")
    InstrumentalReporters.agent = agent
    InstrumentalReporters.activate

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("queue.process", anything)

    Delayed::Job.enqueue(TestDelayedJob.new(success: true))
    Delayed::Worker.new(exit_on_complete: true).start
  end

  it "Resque is instrumented" do
    require "resque"
    Instrumental::Agent.logger = Logger.new(StringIO.new(""))
    agent = Instrumental::Agent.new("test api token")
    InstrumentalReporters.agent = agent
    InstrumentalReporters.activate

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("queue.process", anything)

    # typically instrumental reporters would be loaded in an initalizer
    # and this _extend_ could be done inside the job itself, but here
    # we are in a weird situation.
    TestResqueJob.send(:extend, Instrumental::ResquePlugin)
    Resque.inline = true
    Resque.enqueue(TestResqueJob, { "success" => true })
  end
end
