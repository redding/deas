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

      @splat_sym_param    = Factory.string
      @splat_string_param = Factory.string

      @server_data  = Factory.server_data
      @request_data = Factory.request_data(:params => {
        :splat     => [@splat_sym_param],
        'splat'    => [@splat_string_param],
        :captures  => [Factory.string],
        'captures' => [Factory.string]
      })
      @proxy.run(@server_data, @request_data)
    end

    should "remove any 'splat' or 'captures' params added by Sinatra's router" do
      [:splat, 'splat', :captures, 'captures'].each do |param_name|
        assert_nil @request_data.params[param_name]
      end
    end

    should "build and run a deas runner" do
      assert_equal subject.handler_class, @runner_spy.handler_class

      exp_args = {
        :logger          => @server_data.logger,
        :router          => @server_data.router,
        :template_source => @server_data.template_source,
        :request         => @request_data.request,
        :params          => @request_data.params,
        :route_path      => @request_data.route_path,
        :splat           => @splat_sym_param
      }
      assert_equal exp_args, @runner_spy.args

      assert_true @runner_spy.run_called
    end

    should "prefer splat sym params over splat string params" do
      assert_equal @splat_sym_param, @runner_spy.args[:splat]

      @request_data.params['splat'] = [@splat_string_param]
      proxy = Deas::HandlerProxy.new('EmptyViewHandler')
      Assert.stub(proxy, :handler_class){ EmptyViewHandler }
      proxy.run(@server_data, @request_data)
      assert_equal @splat_string_param, @runner_spy.args[:splat]
    end

    should "add data to the request env to make it available to Rack" do
      exp = subject.handler_class
      assert_equal exp, @request_data.request.env['deas.handler_class']

      exp = @runner_spy.handler
      assert_equal exp, @request_data.request.env['deas.handler']

      exp = @runner_spy.params
      assert_equal exp, @request_data.request.env['deas.params']

      exp = @runner_spy.splat
      assert_equal exp, @request_data.request.env['deas.splat']

      exp = @runner_spy.route_path
      assert_equal exp, @request_data.request.env['deas.route_path']
    end

    should "log the handler class name and the params" do
      exp_msgs = [
        "  Handler: #{subject.handler_class.name}",
        "  Params:  #{@runner_spy.params.inspect}",
        "  Splat:   #{@runner_spy.splat.inspect}",
        "  Route:   #{@runner_spy.route_path.inspect}"
      ]
      assert_equal exp_msgs, @request_data.request.logging_msgs
    end

  end

  class RunnerSpy

    attr_reader :run_called
    attr_reader :handler_class, :handler, :args
    attr_reader :logger, :router, :template_source
    attr_reader :request, :params, :splat, :route_path

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
      @params          = args[:params]
      @splat           = args[:splat]
      @route_path      = args[:route_path]
    end

    def run
      @run_called = true
    end

  end

end
