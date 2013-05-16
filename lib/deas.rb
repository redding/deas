require 'ns-options'
require 'pathname'

require 'deas/version'
require 'deas/exceptions'
require 'deas/server'
require 'deas/view_handler'

# TODO - remove with future version of Rack (> v1.5.2)
require 'deas/rack_request_fix'

module Deas

  class NullLogger
    require 'logger'

    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase){|*args| } # no-op
    end
  end

end
