module Deas

  class NullLogger
    require 'logger'

    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase){|*args| } # no-op
    end

  end

end
