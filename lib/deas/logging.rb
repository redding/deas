require 'benchmark'
require 'sinatra/base'

module Deas

  module Logging
    def self.middleware(verbose)
      verbose ? VerboseLogging : SummaryLogging
    end
  end

  class BaseLogging

    def initialize(app)
      @app    = app
      @logger = @app.settings.logger
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
    # This is the common behavior for both the verbose and summary logging
    # middlewares. It sets rack's logger, times the response and returns it as is.
    def call!(env)
      env['rack.logger'] = @logger

      status, headers, body = nil, nil, nil
      benchmark = Benchmark.measure do
        status, headers, body = @app.call(env)
      end
      log_error(env['sinatra.error'])
      env['deas.time_taken'] = RoundedTime.new(benchmark.real)

      [ status, headers, body ]
    end

    def log(message)
      @logger.info "[Deas] #{message}"
    end

    def log_error(exception)
      return if !exception || exception.kind_of?(Sinatra::NotFound)
      log "#{exception.class}: #{exception.message}\n" \
          "#{exception.backtrace.join("\n")}"
    end

  end

  class VerboseLogging < BaseLogging

    RESPONSE_STATUS_NAMES = {
      200 => 'OK',
      302 => 'FOUND',
      400 => 'BAD REQUEST',
      401 => 'UNAUTHORIZED',
      403 => 'FORBIDDEN',
      404 => 'NOT FOUND',
      408 => 'TIMEOUT',
      500 => 'ERROR'
    }

    # This the real Rack call interface. It adds logging before and after
    # super-ing to the common logging behavior.
    def call!(env)
      log "===== Received request ====="
      Rack::Request.new(env).tap do |request|
        log "  Method:  #{request.request_method.inspect}"
        log "  Path:    #{request.path.inspect}"
      end
      env['deas.logging'] = Proc.new{ |msg| log(msg) }
      status, headers, body = super(env)
      log "  Redir:   #{headers['Location']}" if headers.key?('Location')
      log "===== Completed in #{env['deas.time_taken']}ms (#{response_display(status)}) ====="
      [ status, headers, body ]
    end

    def response_display(status)
      [ status, RESPONSE_STATUS_NAMES[status.to_i] ].compact.join(', ')
    end

  end

  class SummaryLogging < BaseLogging

    # This the real Rack call interface. It adds logging after super-ing to the
    # common logging behavior.
    def call!(env)
      env['deas.logging'] = Proc.new{ |msg| } # no-op
      status, headers, body = super(env)
      request = Rack::Request.new(env)
      line_attrs = {
        'method'  => request.request_method,
        'path'    => request.path,
        'handler' => env['deas.handler_class_name'],
        'params'  => env['deas.params'],
        'time'    => env['deas.time_taken'],
        'status'  => status
      }
      if headers.key?('Location')
        line_attrs['redir'] = headers['Location']
      end
      log SummaryLine.new(line_attrs)
      [ status, headers, body ]
    end

  end

  module SummaryLine
    def self.keys
      %w{time status method path handler params redir}
    end
    def self.new(line_attrs)
      self.keys.select{ |k| line_attrs.key?(k) }.
                map{ |k| "#{k}=#{line_attrs[k].inspect}"  }.
                join(' ')
    end
  end

  module RoundedTime
    ROUND_PRECISION = 2
    ROUND_MODIFIER = 10 ** ROUND_PRECISION
    def self.new(time_in_seconds)
      (time_in_seconds * 1000 * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
    end
  end

end
