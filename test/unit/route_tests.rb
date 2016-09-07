require 'assert'
require 'deas/route'

require 'deas/exceptions'
require 'deas/route_proxy'
require 'test/support/empty_view_handler'

class Deas::Route

  class UnitTests < Assert::Context
    desc "Deas::Route"
    setup do
      @req_type_name   = Factory.string
      @proxy           = HandlerProxySpy.new
      @handler_proxies = Hash.new{ |h, k| raise(Deas::HandlerProxyNotFound) }.tap do |h|
        h[@req_type_name] = @proxy
      end

      @route = Deas::Route.new(:get, '/test', @handler_proxies)
    end
    subject{ @route }

    should have_readers :method, :path
    should have_imeths :validate!, :run

    should "know its method and path" do
      assert_equal :get, subject.method
      assert_equal '/test', subject.path
    end

    should "validate its proxies on validate" do
      assert_false @proxy.validate_called

      assert_nothing_raised{ subject.validate! }
      assert_true @proxy.validate_called
    end

  end

  class RunTests < UnitTests
    desc "when run"
    setup do
      @server_data  = Factory.server_data
      @request_data = Factory.request_data
    end

    should "run the proxy for the given request type name" do
      Assert.stub(@server_data.router, :request_type_name).with(
        @request_data.request
      ){ @req_type_name }

      @route.run(@server_data, @request_data)
      assert_true @proxy.run_called
      assert_equal @server_data, @proxy.server_data
      assert_equal @request_data, @proxy.request_data
    end

    should "halt 404 if it can't find a proxy for the given request type name" do
      exp = [404, Rack::Utils::HeaderHash.new, []]
      assert_equal exp, @route.run(@server_data, @request_data)
    end

  end

  class HandlerProxySpy

    attr_reader :validate_called, :run_called, :server_data, :request_data

    def initialize
      @run_called      = false
      @validate_called = false
      @server_data     = nil
      @request_data    = nil
    end

    def validate!
      @validate_called = true
    end

    def run(server_data, request_data)
      @server_data  = server_data
      @request_data = request_data
      @run_called   = true
    end

  end

end
