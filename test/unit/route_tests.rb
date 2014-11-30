require 'assert'
require 'deas/route'

require 'deas/sinatra_runner'
require 'deas/route_proxy'
require 'test/support/fake_sinatra_call'
require 'test/support/view_handlers'

class Deas::Route

  class UnitTests < Assert::Context
    desc "Deas::Route"
    setup do
      @route_proxy = Deas::RouteProxy.new('EmptyViewHandler')
      @route = Deas::Route.new(:get, '/test', @route_proxy)
    end
    subject{ @route }

    should have_readers :method, :path, :route_proxy, :handler_class
    should have_imeths :validate!, :run

    should "know its method, path and route proxy" do
      assert_equal :get, subject.method
      assert_equal '/test', subject.path
      assert_equal @route_proxy, subject.route_proxy
    end

    should "set its handler class on `validate!`" do
      assert_nil subject.handler_class

      assert_nothing_raised{ subject.validate! }
      assert_equal EmptyViewHandler, subject.handler_class
    end

    should "complain given an invalid handler class" do
      proxy = Deas::RouteProxy.new('SomethingNotDefined')
      assert_raises(Deas::NoHandlerClassError) do
        Deas::Route.new(:get, '/test', proxy).validate!
      end
    end

  end

  class RunTests < UnitTests
    desc "when run"
    setup do
      @fake_sinatra_call = FakeSinatraCall.new
      @runner_spy = SinatraRunnerSpy.new
      Assert.stub(Deas::SinatraRunner, :new) do |*args|
        @runner_spy.build(*args)
        @runner_spy
      end

      @route.validate!
      @route.run(@fake_sinatra_call)
    end

    should "build and run a sinatra runner" do
      assert_equal subject.handler_class, @runner_spy.handler_class

      exp_args = {
        :sinatra_call => @fake_sinatra_call,
        :request      => @fake_sinatra_call.request,
        :response     => @fake_sinatra_call.response,
        :session      => @fake_sinatra_call.session,
        :params       => @fake_sinatra_call.params,
        :logger       => @fake_sinatra_call.settings.logger,
        :router       => @fake_sinatra_call.settings.router,
        :template_source => @fake_sinatra_call.settings.template_source
      }
      assert_equal exp_args, @runner_spy.args

      assert_true @runner_spy.run_called
    end

    should "add the runner params to the request env" do
      exp = @runner_spy.params
      assert_equal exp, @fake_sinatra_call.request.env['deas.params']
    end

    should "add the handler class name to the request env" do
      exp = subject.handler_class.name
      assert_equal exp, @fake_sinatra_call.request.env['deas.handler_class_name']
    end

    should "log the handler and params" do
      exp_msgs = [
        "  Handler: #{subject.handler_class}",
        "  Params:  #{@runner_spy.params.inspect}"
      ]
      assert_equal exp_msgs, @fake_sinatra_call.request.logging_msgs
    end

  end

  class SinatraRunnerSpy

    attr_reader :run_called
    attr_reader :handler_class, :args
    attr_reader :sinatra_call
    attr_reader :request, :response, :session, :params
    attr_reader :logger, :router, :template_source

    def initialize
      @run_called = false
    end

    def build(handler_class, args)
      @handler_class, @args = handler_class, args

      @sinatra_call = args[:sinatra_call]
      @request      = args[:request]
      @response     = args[:response]
      @session      = args[:session]
      @params       = args[:params]
      @logger       = args[:logger]
      @router       = args[:router]
      @template_source = args[:template_source]
    end

    def run
      @run_called = true
    end

  end

end
