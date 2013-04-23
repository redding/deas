# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
ROOT = File.expand_path('../..', __FILE__)
$LOAD_PATH.unshift(ROOT)

# require pry for debugging (`binding.pry`)
require 'pry'
require 'assert-mocha' if defined?(Assert)

require 'deas'
Deas.configure do |config|
  config.routes_file = File.join(ROOT, 'test/support/routes')
end
Deas.init
