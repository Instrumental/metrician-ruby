$:.push File.expand_path("../lib", __FILE__)
require "instrumental_reporters/version"

Gem::Specification.new do |s|
  s.name        = "instrumental_reporters"
  s.version     = InstrumentalReporters::VERSION
  s.authors     = ["Expected Behavior"]
  s.email       = ["support@instrumentalapp.com"]
  s.homepage    = "http://instrumentalapp.com/"
  s.summary     = %q{A summary}
  s.description = %q{A description}
  s.license     = "MIT"


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "app"]
  s.add_dependency(%q<instrumental_agent>, [">= 0"])
end
