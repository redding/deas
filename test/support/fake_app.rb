require 'deas/logger'
require 'ostruct'

class FakeApp

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :halt, :settings

  def initialize
    @request = FakeRequest.new('GET','/something', {})
    @params   = @request.params
    @response = FakeResponse.new
    @settings = OpenStruct.new({
      :runner_logger => Deas::RunnerLogger.new(Deas::NullLogger.new, false)
    })
  end

  def halt(*args)
    throw :halt, *args
  end

  def erb(*args, &block)
    if block
      [ args, block.call ].flatten
    else
      args
    end
  end

end

class FakeRequest < Struct.new(:http_method, :path, :params)
  alias :request_method :http_method
end
FakeResponse = Struct.new(:status, :headers, :body)
