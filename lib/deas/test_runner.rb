require 'ostruct'
require 'deas/runner'

module Deas

  class TestRunner < Runner

    attr_reader :handler, :return_value

    def initialize(handler_class, args = nil)
      args = (args || {}).dup
      @app_settings = OpenStruct.new(args.delete(:app_settings))
      @logger       = args.delete(:logger) || Deas::NullLogger.new
      @params       = args.delete(:params) || {}
      @request      = args.delete(:request)
      @response     = args.delete(:response)
      @session      = args.delete(:session)

      super(handler_class)
      args.each{|key, value| @handler.send("#{key}=", value) }

      @return_value = catch(:halt){ @handler.init; nil }
    end

    def run
      @return_value ||= catch(:halt){ @handler.run }
    end

    # Helpers

    def halt(*args)
      throw(:halt, args)
    end

    def render(*args, &block)
      [ args, block ].compact.flatten
    end

  end

end
