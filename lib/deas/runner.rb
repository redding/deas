module Deas

  class Runner

    attr_reader :app_settings
    attr_reader :request, :response, :params, :logger, :session

    def initialize(handler_class)
      @handler_class = handler_class
      @handler = @handler_class.new(self)
    end

    def halt(*args);         raise NotImplementedError; end
    def redirect(*args);     raise NotImplementedError; end
    def content_type(*args); raise NotImplementedError; end
    def status(*args);       raise NotImplementedError; end
    def headers(*args);      raise NotImplementedError; end
    def render(*args);       raise NotImplementedError; end
    def send_file(*args);    raise NotImplementedError; end

  end

end
