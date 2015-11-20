require 'rack/multipart'
require 'deas/router'
require 'deas/runner'
require 'deas/view_handler'

module Deas

  InvalidServiceHandlerError = Class.new(StandardError)

  class TestRunner < Runner

    attr_reader :response_value

    def initialize(handler_class, args = nil)
      if !handler_class.include?(Deas::ViewHandler)
        raise InvalidServiceHandlerError, "#{handler_class.inspect} is not a"\
                                          " Deas::ViewHandler"
      end

      args = (args || {}).dup
      super(handler_class, {
        :logger          => args.delete(:logger),
        :router          => args.delete(:router),
        :template_source => args.delete(:template_source),
        :request         => args.delete(:request),
        :session         => args.delete(:session),
        :params          => NormalizedParams.new(args.delete(:params) || {}).value
      })
      args.each{|key, value| self.handler.send("#{key}=", value) }

      @response_value = catch(:halt){ self.handler.init; nil }
    end

    def run
      @response_value ||= catch(:halt){ self.handler.run }
    end

    # Helpers

    def halt(*args)
      throw(:halt, HaltArgs.new(args))
    end

    class HaltArgs < Struct.new(:body, :headers, :status)
      def initialize(args)
        super(*[
          !args.last.kind_of?(::Hash) && !args.last.kind_of?(::Integer) ? args.pop : nil,
          args.last.kind_of?(::Hash) ? args.pop : nil,
          args.first.kind_of?(::Integer) ? args.first : nil
        ])
      end
    end

    def redirect(path, *halt_args)
      throw(:halt, RedirectArgs.new(path, halt_args))
    end

    class RedirectArgs < Struct.new(:path, :halt_args)
      def redirect?; true; end
    end

    def content_type(*args)
      return @content_type if args.empty?
      opts, value = [
        args.last.kind_of?(Hash) ? args.pop : {},
        args.last
      ]
      @content_type = ContentTypeArgs.new(value, opts)
    end
    ContentTypeArgs = Struct.new(:value, :opts)

    def status(*args)
      return @status if args.empty?
      value = args.last
      @status = StatusArgs.new(value)
    end
    StatusArgs = Struct.new(:value)

    def headers(*args)
      return @headers if args.empty?
      value = args.last
      @headers = HeadersArgs.new(value)
    end
    HeadersArgs = Struct.new(:value)

    def send_file(file_path, options = nil, &block)
      SendFileArgs.new(file_path, options, block)
    end
    SendFileArgs = Struct.new(:file_path, :options, :block)

    def source_render(source, template_name, locals = nil)
      super # render the markup and discard it
      RenderArgs.new(source, template_name, locals)
    end
    RenderArgs = Struct.new(:source, :template_name, :locals)

    def source_partial(source, template_name, locals = nil)
      super # render the markup and discard it
      RenderArgs.new(source, template_name, locals)
    end

    class NormalizedParams < Deas::Runner::NormalizedParams
      def file_type?(value)
        value.kind_of?(::Tempfile) ||
        value.kind_of?(::File) ||
        value.kind_of?(::Rack::Multipart::UploadedFile) ||
        (defined?(::Rack::Test::UploadedFile) && value.kind_of?(::Rack::Test::UploadedFile))
      end
    end

  end

end
