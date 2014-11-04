require 'rack/multipart'
require 'deas/router'
require 'deas/runner'

module Deas

  class TestRunner < Runner

    attr_reader :return_value

    def initialize(handler_class, args = nil)
      args = (args || {}).dup

      super(handler_class, {
        :request  => args.delete(:request),
        :response => args.delete(:response),
        :params   => NormalizedParams.new(args.delete(:params) || {}).value,
        :logger   => args.delete(:logger),
        :router   => args.delete(:router),
        :session  => args.delete(:session)
      })
      args.each{|key, value| self.handler.send("#{key}=", value) }

      @return_value = catch(:halt){ self.handler.init; nil }
    end

    def run
      @return_value ||= catch(:halt){ self.handler.run }
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

    def content_type(value, opts={})
      ContentTypeArgs.new(value, opts)
    end
    ContentTypeArgs = Struct.new(:value, :opts)

    def status(value)
      StatusArgs.new(value)
    end
    StatusArgs = Struct.new(:value)

    def headers(value)
      HeadersArgs.new(value)
    end
    HeadersArgs = Struct.new(:value)

    def render(template_name, options = nil, &block)
      RenderArgs.new(template_name, options, block)
    end
    RenderArgs = Struct.new(:template_name, :options, :block)

    def send_file(file_path, options = nil, &block)
      SendFileArgs.new(file_path, options, block)
    end
    SendFileArgs = Struct.new(:file_path, :options, :block)

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
