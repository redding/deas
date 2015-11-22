require 'assert'
require 'deas/handler_proxy'

require 'deas/exceptions'
require 'deas/deas_runner'
require 'test/support/empty_view_handler'

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
      @runner_spy = RunnerSpy.new
      Assert.stub(Deas::DeasRunner, :new) do |*args|
        @runner_spy.build(*args)
        @runner_spy
      end

      Assert.stub(@proxy, :handler_class){ EmptyViewHandler }

      @server_data       = Factory.server_data
      @fake_sinatra_call = Factory.sinatra_call
      @fake_sinatra_call.params = {
        :splat     => Factory.string,
        'splat'    => Factory.string,
        :captures  => [Factory.string],
        'captures' => [Factory.string]
      }

      @proxy.run(@server_data, @fake_sinatra_call)
    end

    should "remove any 'splat' or 'captures' params added by Sinatra's router" do
      [:splat, 'splat', :captures, 'captures'].each do |param_name|
        assert_nil @fake_sinatra_call.params[param_name]
      end
    end

    should "build and run a deas runner" do
      assert_equal subject.handler_class, @runner_spy.handler_class

      exp_args = {
        :logger          => @server_data.logger,
        :router          => @server_data.router,
        :template_source => @server_data.template_source,
        :request         => @fake_sinatra_call.request,
        :session         => @fake_sinatra_call.session,
        :params          => @fake_sinatra_call.params
      }
      assert_equal exp_args, @runner_spy.args

      assert_true @runner_spy.run_called
    end

    should "add data to the request env to make it available to Rack" do
      exp = subject.handler_class
      assert_equal exp, @fake_sinatra_call.request.env['deas.handler_class']

      exp = @runner_spy.handler
      assert_equal exp, @fake_sinatra_call.request.env['deas.handler']

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

  class RunnerSpy

    attr_reader :run_called
    attr_reader :handler_class, :handler, :args
    attr_reader :logger, :router, :template_source
    attr_reader :request, :session, :params

    def initialize
      @run_called = false
    end

    def build(handler_class, args)
      @handler_class = handler_class
      @handler       = handler_class.new(self)
      @args          = args

      @logger          = args[:logger]
      @router          = args[:router]
      @template_source = args[:template_source]
      @request         = args[:request]
      @session         = args[:session]
      @params          = args[:params]
    end

    def run
      @run_called = true
    end

  end

end
