require 'rack/utils'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'

module Deas

  class Runner

    attr_reader :handler_class, :handler
    attr_reader :logger, :router, :template_source
    attr_reader :request, :session, :params

    def initialize(handler_class, args = nil)
      @handler_class = handler_class
      @handler = @handler_class.new(self)

      args ||= {}
      @logger          = args[:logger] || Deas::NullLogger.new
      @router          = args[:router] || Deas::Router.new
      @template_source = args[:template_source] || Deas::NullTemplateSource.new
      @request         = args[:request]
      @session         = args[:session]
      @params          = args[:params] || {}
    end

    def halt(*args);           raise NotImplementedError; end
    def redirect(*args);       raise NotImplementedError; end
    def content_type(*args);   raise NotImplementedError; end
    def status(*args);         raise NotImplementedError; end
    def headers(*args);        raise NotImplementedError; end
    def send_file(*args);      raise NotImplementedError; end

    # the render methods are used by both the deas and test runners
    # so we implement here

    def render(template_name, locals = nil)
      source_render(self.template_source, template_name, locals)
    end

    def source_render(source, template_name, locals = nil)
      source.render(template_name, self.handler, locals || {})
    end

    def partial(template_name, locals = nil)
      source_partial(self.template_source, template_name, locals)
    end

    def source_partial(source, template_name, locals = nil)
      source.partial(template_name, locals || {})
    end

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
