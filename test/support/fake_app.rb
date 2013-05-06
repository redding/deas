require 'deas'
require 'ostruct'

class FakeApp

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :settings, :session

  def initialize
    @request = FakeRequest.new('GET','/something', {}, OpenStruct.new)
    @params   = @request.params
    @session  = @request.session
    @response = FakeResponse.new
    @settings = OpenStruct.new({ })
  end

  def halt(*args)
    throw :halt, args
  end

  def erb(*args, &block)
    if block
      [ args, block.call ].flatten
    else
      args
    end
  end

  def to(relative_path)
    File.join("http://test.local", relative_path)
  end

  def redirect(*args)
    halt 302, { 'Location' => args[0] }
  end

end

class FakeRequest < Struct.new(:http_method, :path, :params, :session)
  alias :request_method :http_method
end
FakeResponse = Struct.new(:status, :headers, :body)
