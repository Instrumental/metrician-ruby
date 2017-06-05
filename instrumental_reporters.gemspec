$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "instrumental_reporters/version"

Gem::Specification.new do |s|
  s.name        = "instrumental_reporters"
  s.version     = InstrumentalReporters::VERSION
  s.authors     = ["Expected Behavior"]
  s.email       = ["support@instrumentalapp.com"]
  s.homepage    = "http://instrumentalapp.com/"
  s.summary     = "A summary"
  s.description = "A description"
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w[lib app]

  s.add_dependency("instrumental_agent", [">= 0"])
  s.add_development_dependency("rubocop")
end
