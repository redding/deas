# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
require 'pathname'
ROOT = Pathname.new(File.expand_path('../..', __FILE__))
$LOAD_PATH.unshift(ROOT.to_s)
TEST_SUPPORT_ROOT = ROOT.join('test/support')

# require pry for debugging (`binding.pry`)
require 'pry'

require 'test/support/factory'

# 1.8.7 backfills

# Array#sample
if !(a = Array.new).respond_to?(:sample) && a.respond_to?(:choice)
  class Array
    alias_method :sample, :choice
  end
end

require 'fileutils'
require 'logger'
log_file_path = ROOT.join("log/test.log")
FileUtils.rm_f log_file_path
TEST_LOGGER = Logger.new(File.open(log_file_path, 'w'))

require TEST_SUPPORT_ROOT.join('routes')

