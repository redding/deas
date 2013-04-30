module Deas

  class Runner

    attr_accessor :request, :response, :params, :logger, :session

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

    def redirect(*args)
      raise NotImplementedError
    end

    def redirect_to(*args)
      raise NotImplementedError
    end

  end

end
