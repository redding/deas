require 'deas/runner'
require 'deas/template'

module Deas

  class SinatraRunner < Runner

    def initialize(handler_class, sinatra_call)
      @sinatra_call  = sinatra_call
      @handler_class = handler_class
      @logger        = @sinatra_call.settings.logger
      @runner_logger = @sinatra_call.settings.runner_logger
      @params        = @sinatra_call.params
      @request       = @sinatra_call.request
      @response      = @sinatra_call.response
      @time_taken    = nil
      @started_at    = nil
      super(handler_class)
    end

    def setup
      @started_at = Time.now
      log_verbose "===== Received request ====="
      log_verbose "  Method:  #{@request.request_method.inspect}"
      log_verbose "  Path:    #{@request.path.inspect}"
      log_verbose "  Params:  #{@sinatra_call.params.inspect}"
      log_verbose "  Handler: #{@handler_class}"
      self
    end

    def run
      run_callbacks @handler_class.before_callbacks
      @handler.init
      response_data = @handler.run
      run_callbacks @handler_class.after_callbacks
      response_data
    end

    # expects that `setup` has been run; this method is dependent on it
    CODE_NAMES = {
      200 => 'OK',
      400 => 'BAD REQUEST' ,
      401 => 'UNAUTHORIZED',
      403 => 'FORBIDDEN',
      404 => 'NOT FOUND',
      408 => 'TIMEOUT',
      500 => 'ERROR'
    }
    def teardown
      @time_taken = RoundedTime.new(Time.now - @started_at)
      @response.status.tap do |code|
        response_display = [ code, CODE_NAMES[code.to_i] ].compact.join(', ')
        log_verbose "===== Completed in #{@time_taken}ms " \
                    "#{response_display} ====="
      end
      log_summary SummaryLine.new({
        'status'  => @response.status,
        'method'  => @request.request_method,
        'path'    => @request.path,
        'params'  => @params,
        'time'    => @time_taken,
        'handler' => @handler_class
      })
      self
    end

    def log_verbose(message, level = :info)
      @runner_logger.verbose.send(level, "[Deas] #{message}")
    end

    def log_summary(message, level = :info)
      @runner_logger.summary.send(level, "[Deas] #{message}")
    end


    # Helpers

    def halt(*args)
      @sinatra_call.halt(*args)
    end

    def render(name, options = nil, &block)
      options ||= {}
      options[:locals] = { :view => @handler }.merge(options[:locals] || {})
      options[:layout] ||= @handler_class.layouts
      Deas::Template.new(@sinatra_call, name, options).render(&block)
    end

    # TODO implement these
    # redirect
    # redirect_to
    # session

    private

    def run_callbacks(callbacks)
      callbacks.each{|proc| @handler.instance_eval(&proc) }
    end

    module RoundedTime
      ROUND_PRECISION = 2
      ROUND_MODIFIER = 10 ** ROUND_PRECISION
      def self.new(time_in_seconds)
        (time_in_seconds * 1000 * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
      end
    end

    module SummaryLine
      def self.new(line_attrs)
        attr_keys = %w{time status handler method path params}
        attr_keys.map{ |k| "#{k}=#{line_attrs[k].inspect}" }.join(' ')
      end
    end

  end
end
