$:.push File.expand_path("../lib", __FILE__)
require "instrumental_rails/version"

Gem::Specification.new do |s|
  s.name        = "instrumental_rails"
  s.version     = InstrumentalRails::VERSION
  s.authors     = ["Expected Behavior"]
  s.email       = ["support@instrumentalapp.com"]
  s.homepage    = "TODO"
  s.summary     = %q{TODO}
  s.description = %q{TODO}
  s.license     = "MIT"


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency(%q<instrumental_agent>, [">= 0"])
end
