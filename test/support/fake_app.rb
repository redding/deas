require 'ostruct'

class FakeApp

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :halt, :settings

  def initialize
    @settings = OpenStruct.new({})
  end

end
