require 'rack/utils'

module Deas

  class ShowExceptions

    def initialize(app)
      @app = app
    end

    # The Rack call interface. The receiver acts as a prototype and runs
    # each request in a clone object unless the +rack.run_once+ variable is
    # set in the environment. Ripped from:
    # http://github.com/rtomayko/rack-cache/blob/master/lib/rack/cache/context.rb
    def call(env)
      if env['rack.run_once']
        call! env
      else
        clone.call! env
      end
    end

    # The real Rack call interface.
    def call!(env)
      status, headers, body = @app.call(env)
      if error = env['sinatra.error']
        error_body = Body.new(error)

        headers['Content-Length'] = error_body.size.to_s
        headers['Content-Type'] = error_body.mime_type.to_s
        body = [error_body.content]
      end
      [ status, headers, body ]
    end

    class Body
      attr_reader :content
      def initialize(e)
        @content ||= "#{e.class}: #{e.message}\n#{(e.backtrace || []).join("\n")}"
      end

      def size
        @size ||= Rack::Utils.bytesize(self.content)
      end

      def mime_type
        @mime_type ||= "text/plain"
      end
    end

  end

end
