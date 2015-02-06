require 'rack/request'
require 'rack/response'
require 'deas/test_runner'

module Deas

  module TestHelpers

    def test_runner(handler_class, args = nil)
      args ||= {}
      args[:request]  ||= Rack::Request.new({})
      args[:response] ||= Rack::Response.new
      args[:session]  ||= args[:request].session
      TestRunner.new(handler_class, args)
    end

    def test_handler(handler_class, args = nil)
      test_runner(handler_class, args).handler
    end

  end

end
