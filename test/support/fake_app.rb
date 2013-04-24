require 'deas/logger'
require 'ostruct'

class FakeApp

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :halt, :settings

  def initialize
    @request  = FakeRequest.new({})
    @params   = @request.params
    @response = FakeResponse.new
    @settings = OpenStruct.new({
      :deas_logger => Deas::NullLogger.new
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

FakeRequest  = Struct.new(:params)
FakeResponse = Struct.new(:code, :headers, :body)
