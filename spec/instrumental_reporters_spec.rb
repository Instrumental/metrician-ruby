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
    agent.should_receive(:gauge).with("database.sql.select", anything)

    User.where(name: "foobar").to_a
  end

  it "DelayedJob is instrumented" do
    require "delayed_job_active_record"
    Instrumental::Agent.logger = Logger.new(StringIO.new(""))
    agent = Instrumental::Agent.new("test api token")
    InstrumentalReporters.agent = agent
    InstrumentalReporters.activate

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("jobs.TestDelayedJob", anything)

    Delayed::Job.enqueue(TestDelayedJob.new(success: true))
    Delayed::Worker.new(exit_on_complete: true).start
  end
end
