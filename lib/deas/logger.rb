module Deas

  class RunnerLogger
    attr_reader :summary, :verbose

    def initialize(logger, verbose = true)
      loggers = [ logger, Deas::NullLogger.new ]
      loggers.reverse! if !verbose
      @verbose, @summary = loggers
    end

  end

  class NullLogger
    require 'logger'

    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase){|*args| } # no-op
    end

  end

end
