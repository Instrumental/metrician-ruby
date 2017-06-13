require "bundler/setup"
require "instrumental_reporters"
require "gemika"
require "byebug"

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :should
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end
