module Deas; end
class Deas::Runner

  class NormalizedParamsSpy
    attr_reader :params, :value_called

    def initialize
      @params = nil
      @value_called = false
    end

    def new(params)
      @params = params
      self
    end

    def value
      @value_called = true
      @params
    end

  end

end
