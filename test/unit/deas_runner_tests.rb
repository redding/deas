require 'assert'
require 'deas/deas_runner'

require 'deas/runner'
require 'deas/template_source'
require 'test/support/normalized_params_spy'

class Deas::DeasRunner

  class UnitTests < Assert::Context
    desc "Deas::DeasRunner"
    setup do
      @handler_class = TestViewHandler
      @runner_class  = Deas::DeasRunner
    end
    subject{ @runner_class }

    should "be a runner" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @params = { 'value' => '1' }
      @norm_params_spy = Deas::Runner::NormalizedParamsSpy.new
      Assert.stub(NormalizedParams, :new){ |p| @norm_params_spy.new(p) }

      @runner = @runner_class.new(@handler_class, :params => @params)
    end
    subject{ @runner }

    should have_imeths :run

    should "call to normalize its params" do
      assert_equal @params, @norm_params_spy.params
      assert_true @norm_params_spy.value_called
    end

    should "super its params arg" do
      assert_equal @params, subject.params
    end

  end

  class InitHandlerTests < InitTests
    setup do
      @handler = @runner.instance_variable_get("@handler")
    end

    private

    def subject_to_rack_with_content_length
      subject.to_rack.tap do |(s,h,b)|
        h.merge!('Content-Length' => calc_content_length(b))
      end
    end

    def calc_content_length(body)
      body.inject(0){ |l, p| l + p.size }.to_s
    end

  end

  class RunTests < InitHandlerTests
    desc "and run"
    setup do
      @response = @runner.run
    end

    should "run the handler's before callbacks" do
      assert_equal 1, @handler.first_before_call_order
      assert_equal 2, @handler.second_before_call_order
    end

    should "run the handler's init and run methods" do
      assert_equal 3, @handler.init_call_order
      assert_equal 4, @handler.run_call_order
    end

    should "run the handler's after callbacks" do
      assert_equal 5, @handler.first_after_call_order
      assert_equal 6, @handler.second_after_call_order
    end

    should "set the content length header in its response" do
      status, headers, body = *@response
      exp = calc_content_length(body)
      assert_equal exp, headers['Content-Length']
    end

    should "only set the content length if it is not already set" do
      custom_content_length = Factory.integer.to_s
      subject.headers['Content-Length'] = custom_content_length

      headers  = @runner.run[1]
      assert_equal custom_content_length, headers['Content-Length']
    end

    should "return its `to_rack` value" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithInitHaltTests < InitHandlerTests
    desc "with a handler that halts on init"
    setup do
      @runner = @runner_class.new(@handler_class, :params => {
        'halt' => 'init'
      })
      @handler  = @runner.handler
      @response = @runner.run
    end

    should "run the before and after callbacks despite the halt" do
      assert_not_nil @handler.first_before_call_order
      assert_not_nil @handler.second_before_call_order
      assert_not_nil @handler.first_after_call_order
      assert_not_nil @handler.second_after_call_order
    end

    should "stop processing when the halt is called" do
      assert_not_nil @handler.init_call_order
      assert_nil @handler.run_call_order
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithRunHaltTests < InitHandlerTests
    desc "with a handler that halts on run"
    setup do
      @runner = @runner_class.new(@handler_class, :params => {
        'halt' => 'run'
      })
      @handler  = @runner.handler
      @response = @runner.run
    end

    should "run the before and after callbacks despite the halt" do
      assert_not_nil @handler.first_before_call_order
      assert_not_nil @handler.second_before_call_order
      assert_not_nil @handler.first_after_call_order
      assert_not_nil @handler.second_after_call_order
    end

    should "stop processing when the halt is called" do
      assert_not_nil @handler.init_call_order
      assert_not_nil @handler.run_call_order
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithBeforeHaltTests < InitHandlerTests
    desc "with a handler that halts in a before callback"
    setup do
      @runner = @runner_class.new(@handler_class, :params => {
        'halt' => 'before'
      })
      @handler  = @runner.handler
      @response = @runner.run
    end

    should "stop processing when the halt is called" do
      assert_not_nil @handler.first_before_call_order
      assert_nil @handler.second_before_call_order
    end

    should "not run the after callbacks b/c of the halt" do
      assert_nil @handler.first_after_call_order
      assert_nil @handler.second_after_call_order
    end

    should "not run the handler's init and run b/c of the halt" do
      assert_nil @handler.init_call_order
      assert_nil @handler.run_call_order
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithAfterHaltTests < InitHandlerTests
    desc "with a handler that halts in an after callback"
    setup do
      @runner = @runner_class.new(@handler_class, :params => {
        'halt' => 'after'
      })
      @handler  = @runner.handler
      @response = @runner.run
    end

    should "run the before callback despite the halt" do
      assert_not_nil @handler.first_before_call_order
      assert_not_nil @handler.second_before_call_order
    end

    should "run the handler's init and run despite the halt" do
      assert_not_nil @handler.init_call_order
      assert_not_nil @handler.run_call_order
    end

    should "stop processing when the halt is called" do
      assert_not_nil @handler.first_after_call_order
      assert_nil @handler.second_after_call_order
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class NormalizedParamsTests < UnitTests
    desc "NormalizedParams"
    setup do
      @norm_params_class = Deas::DeasRunner::NormalizedParams
    end

    should "be a normalized params subclass" do
      assert @norm_params_class < Deas::Runner::NormalizedParams
    end

    should "not convert Tempfile param values to strings" do
      tempfile = Class.new(::Tempfile){ def initialize; end }.new
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of ::Tempfile, params['attachment']['tempfile']
    end

    private

    def normalized(params)
      @norm_params_class.new(params).value
    end

  end

  class TestViewHandler
    include Deas::ViewHandler

    attr_accessor :halt_in_before, :halt_in_after
    attr_reader :first_before_call_order, :second_before_call_order
    attr_reader :first_after_call_order, :second_after_call_order
    attr_reader :init_call_order, :run_call_order

    before{ @first_before_call_order = next_call_order; halt_if('before') }
    before{ @second_before_call_order = next_call_order }

    after{ @first_after_call_order = next_call_order; halt_if('after') }
    after{ @second_after_call_order = next_call_order }

    def init!
      @init_call_order = next_call_order
      halt_if('init')
    end

    def run!
      @run_call_order = next_call_order
      halt_if('run')
      body Factory.integer(3).times.map{ Factory.text }
    end

    private

    def next_call_order; @order ||= 0; @order += 1; end

    def halt_if(value)
      halt Factory.integer if params['halt'] == value
    end

  end

end
