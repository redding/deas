require 'rack/multipart'
require 'deas/router'
require 'deas/runner'
require 'deas/view_handler'

module Deas

  InvalidViewHandlerError = Class.new(StandardError)

  class TestRunner < Runner

    attr_reader :content_type_args

    def initialize(handler_class, args = nil)
      if !handler_class.include?(Deas::ViewHandler)
        raise InvalidViewHandlerError, "#{handler_class.inspect} is not a " \
                                       "Deas::ViewHandler"
      end

      a = (args || {}).dup
      super(handler_class, {
        :logger          => a.delete(:logger),
        :router          => a.delete(:router),
        :template_source => a.delete(:template_source),
        :request         => a.delete(:request),
        :session         => a.delete(:session),
        :params          => NormalizedParams.new(a.delete(:params) || {}).value
      })
      a.each{|key, value| self.handler.send("#{key}=", value) }

      @run_return_value  = nil
      @content_type_args = nil
      @halted            = false

      catch(:halt){ self.handler.deas_init }
    end

    def halted?; @halted; end

    def run
      catch(:halt){ self.handler.deas_run } if !self.halted?
      @run_return_value
    end

    # helpers

    def content_type(extname, params = nil)
      @content_type_args = ContentTypeArgs.new(extname, params)
      super
    end

    def halt(*args)
      @halted = true
      @run_return_value ||= HaltArgs.new(args)
      super
    end

    def redirect(location, *halt_args)
      @run_return_value ||= RedirectArgs.new(location, HaltArgs.new(halt_args))
      super
    end

    def send_file(file_path, opts = nil)
      @run_return_value ||= SendFileArgs.new(file_path, opts)
      super
    end

    def source_render(source, template_name, locals = nil)
      @run_return_value ||= RenderArgs.new(source, template_name, locals)
      super
    end

    def source_partial(source, template_name, locals = nil)
      # partials don't interact with the response body so they shouldn't affect
      # the run return value (like renders do).  Render the markup and discard
      # it to test the template.  Return the render args so you can test the
      # expected partials were rendered.
      super
      RenderArgs.new(source, template_name, locals)
    end

    ContentTypeArgs = Struct.new(:extname, :params)

    class HaltArgs < Struct.new(:status, :headers, :body)
      def initialize(args)
        a = args.dup
        super(*[
          a.first.instance_of?(::Fixnum) ? a.shift : nil,
          a.first.kind_of?(::Hash)       ? a.shift : nil,
          a.first.respond_to?(:each)     ? a.shift : nil
        ])
      end
    end

    class RedirectArgs < Struct.new(:location, :halt_args)
      def redirect?; true; end
    end

    SendFileArgs = Struct.new(:file_path, :opts)
    RenderArgs   = Struct.new(:source, :template_name, :locals)

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
