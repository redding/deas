module Deas

  class ErrorHandler

    def self.run(*args)
      self.new(*args).run
    end

    attr_reader :exception, :context, :error_procs

    def initialize(exception, context_hash)
      @exception   = exception
      @context     = Context.new(context_hash)
      @error_procs = context_hash[:server_data].error_procs.reverse
    end

    # The exception that we are generating a response for can change in the case
    # that the configured error proc raises an exception. If this occurs, a
    # response will be generated for that exception, instead of the original
    # one. This is designed to avoid "hidden" errors happening, this way the
    # server will respond and log based on the last exception that occurred.

    def run
      @error_procs.inject(nil) do |response, error_proc|
        result = begin
          error_proc.call(@exception, @context)
        rescue StandardError => proc_exception
          @exception = proc_exception
          response   = nil # reset response
        end
        response || result
      end
    end

    class Context

      attr_reader :server_data
      attr_reader :request, :response, :handler_class, :handler
      attr_reader :params, :splat, :route_path

      def initialize(args)
        @server_data   = args.fetch(:server_data)
        @request       = args.fetch(:request)
        @response      = args.fetch(:response)
        @handler_class = args.fetch(:handler_class)
        @handler       = args.fetch(:handler)
        @params        = args.fetch(:params)
        @splat         = args.fetch(:splat)
        @route_path    = args.fetch(:route_path)
      end

      def ==(other)
        if other.kind_of?(self.class)
          self.server_data   == other.server_data   &&
          self.handler_class == other.handler_class &&
          self.request       == other.request       &&
          self.response      == other.response      &&
          self.handler       == other.handler       &&
          self.params        == other.params        &&
          self.splat         == other.splat         &&
          self.route_path    == other.route_path
        else
          super
        end
      end

    end

  end

end
