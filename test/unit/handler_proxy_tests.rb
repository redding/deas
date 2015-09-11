require 'assert'
require 'deas/handler_proxy'

require 'deas/exceptions'
require 'deas/sinatra_runner'
require 'test/support/view_handlers'

class Deas::HandlerProxy

  class UnitTests < Assert::Context
    desc "Deas::HandlerProxy"
    setup do
      @proxy = Deas::HandlerProxy.new('EmptyViewHandler')
    end
    subject{ @proxy }

    should have_readers :handler_class_name, :handler_class
    should have_imeths :validate!, :run

    should "know its handler class name" do
      assert_equal 'EmptyViewHandler', subject.handler_class_name
    end

    should "not implement its validate! method" do
      assert_raises(NotImplementedError){ subject.validate! }
    end

  end

  class RunTests < UnitTests
    desc "when run"
    setup do
      @runner_spy = SinatraRunnerSpy.new
      Assert.stub(Deas::SinatraRunner, :new) do |*args|
        @runner_spy.build(*args)
        @runner_spy
      end

      Assert.stub(@proxy, :handler_class){ EmptyViewHandler }

      @server_data       = Factory.server_data
      @fake_sinatra_call = Factory.sinatra_call
      @proxy.run(@server_data, @fake_sinatra_call)
    end

    should "build and run a sinatra runner" do
      assert_equal subject.handler_class, @runner_spy.handler_class

      exp_args = {
        :sinatra_call    => @fake_sinatra_call,
        :request         => @fake_sinatra_call.request,
        :response        => @fake_sinatra_call.response,
        :session         => @fake_sinatra_call.session,
        :params          => @fake_sinatra_call.params,
        :logger          => @server_data.logger,
        :router          => @server_data.router,
        :template_source => @server_data.template_source
      }
      assert_equal exp_args, @runner_spy.args

      assert_true @runner_spy.run_called
    end

    should "add the handler class to the request env" do
      exp = subject.handler_class
      assert_equal exp, @fake_sinatra_call.request.env['deas.handler_class']
    end

    should "add the runner params to the request env" do
      exp = @runner_spy.params
      assert_equal exp, @fake_sinatra_call.request.env['deas.params']
    end

    should "log the handler class name and the params" do
      exp_msgs = [
        "  Handler: #{subject.handler_class.name}",
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

      @sinatra_call    = args[:sinatra_call]
      @request         = args[:request]
      @response        = args[:response]
      @session         = args[:session]
      @params          = args[:params]
      @logger          = args[:logger]
      @router          = args[:router]
      @template_source = args[:template_source]
    end

    def run
      @run_called = true
    end

  end

end
