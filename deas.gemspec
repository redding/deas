# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "deas/version"

Gem::Specification.new do |gem|
  gem.name        = "deas"
  gem.version     = Deas::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.summary     = %q{Handler-based web framework powered by Sinatra}
  gem.description = %q{Handler-based web framework powered by Sinatra}
  gem.homepage    = "http://github.com/redding/deas"
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert",           ["~> 2.16.3"])
  gem.add_development_dependency("assert-rack-test", ["~> 1.0.5"])

  gem.add_dependency("much-plugin", ["~> 0.2.0"])
  gem.add_dependency("rack",        ["~> 1.1"])
  gem.add_dependency("sinatra",     ["~> 1.2"])

end
