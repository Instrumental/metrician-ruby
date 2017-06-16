$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "metrician/version"

Gem::Specification.new do |s|
  s.name        = "metrician"
  s.version     = Metrician::VERSION
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
  s.add_development_dependency "bundler", "~> 1.14"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "byebug"
end
