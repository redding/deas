require 'rack/utils'

module Deas

  class Runner

    attr_reader :handler_class, :handler
    attr_reader :request, :response, :params
    attr_reader :logger, :router, :session

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
    def partial(*args);      raise NotImplementedError; end
    def send_file(*args);    raise NotImplementedError; end

    class NormalizedParams

      attr_reader :value

      def initialize(value)
        @value = if value.is_a?(::Array)
          value.map{ |i| self.class.new(i).value }
        elsif Rack::Utils.params_hash_type?(value)
          value.inject({}){ |h, (k, v)| h[k.to_s] = self.class.new(v).value; h }
        elsif self.file_type?(value)
          value
        else
          value.to_s
        end
      end

      def file_type?(value)
        raise NotImplementedError
      end

    end

  end

end
