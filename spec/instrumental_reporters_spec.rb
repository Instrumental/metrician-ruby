require "spec_helper"

RSpec.describe InstrumentalReporters do
  it "has a version number" do
    InstrumentalReporters::VERSION.should_not be nil
  end

  it "does something useful" do
    agent = Instrumental::Agent.new("test api token")
    InstrumentalReporters.agent = agent
    InstrumentalReporters.activate

    agent.stub(:gauge)
    agent.should_receive(:gauge).with("database.sql.select", anything)

    User.where(name: "foobar").to_a
  end
end
