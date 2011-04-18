# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "text_tractor/version"

Gem::Specification.new do |s|
  s.name        = "TextTractor"
  s.version     = TextTractor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jon Wood"]
  s.email       = ["jon@blankpad.net"]
  s.homepage    = "https://github.com/jellybob/text_tractor"
  s.summary     = %q{An implementation of the server side for a certain web service.}
  s.description = %q{TextTractor provides a web interface so that your clients can edit their copy, while you get on with more interesting things.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "haml"
  s.add_dependency "sass"
  s.add_dependency "sinatra"
  s.add_dependency "json"
  s.add_dependency "redis"
  s.add_dependency "redis-namespace"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "capybara"
end
