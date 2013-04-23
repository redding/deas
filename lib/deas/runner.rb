module Deas

  class Runner

    attr_accessor :request, :response, :params, :logger

    def initialize(handler_class)
      @handler_class = handler_class
      @handler = @handler_class.new(self)
    end

    def halt(*args)
      raise NotImplementedError
    end

    def render(*args)
      raise NotImplementedError
    end

  end

end
