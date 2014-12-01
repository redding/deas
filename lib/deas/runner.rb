# need to define class immediately b/c of circular requires:
# - runner -> router -> route -> deas_runner -> runner
module Deas; end
class Deas::Runner; end

require 'rack/utils'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'

module Deas

  class Runner

    attr_reader :handler_class, :handler
    attr_reader :request, :response, :session
    attr_reader :params, :logger, :router, :template_source

    def initialize(handler_class, args = nil)
      @handler_class = handler_class
      @handler = @handler_class.new(self)

      a = args || {}
      @request         = a[:request]
      @response        = a[:response]
      @session         = a[:session]
      @params          = a[:params] || {}
      @logger          = a[:logger] || Deas::NullLogger.new
      @router          = a[:router] || Deas::Router.new
      @template_source = a[:template_source] || Deas::NullTemplateSource.new
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
