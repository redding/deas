require 'assert'
require 'deas/deas_runner'

require 'deas/runner'
require 'deas/template_source'
require 'test/support/normalized_params_spy'
require 'test/support/view_handlers'

class Deas::DeasRunner

  class UnitTests < Assert::Context
    desc "Deas::DeasRunner"
    setup do
      @handler_class = DeasRunnerViewHandler
      @runner_class  = Deas::DeasRunner
    end
    subject{ @runner_class }

    should "be a `Runner`" do
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

    should "run the before and after callbacks" do
      assert_equal true, @handler.before_called
      assert_equal true, @handler.after_called
    end

    should "run the handler's init and run" do
      assert_equal true, @handler.init_bang_called
      assert_equal true, @handler.run_bang_called
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
      Assert.stub(@handler, :init!){ @runner.halt }
      @response = @runner.run
    end

    should "run the before and after callbacks despite the halt" do
      assert_equal true, @handler.before_called
      assert_equal true, @handler.after_called
    end

    should "not run the handler's run b/c of the halt" do
      assert_not_equal true, @handler.run_bang_called
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithRunHaltTests < InitHandlerTests
    desc "with a handler that halts on run"
    setup do
      Assert.stub(@handler, :run!){ @runner.halt }
      @response = @runner.run
    end

    should "run the before and after callbacks despite the halt" do
      assert_equal true, @handler.before_called
      assert_equal true, @handler.after_called
    end

    should "run the handler's init despite the halt" do
      assert_equal true, @handler.init_bang_called
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithBeforeHaltTests < InitHandlerTests
    desc "with a handler that halts in a before callback"
    setup do
      @handler.halt_in_before = true
      @response = @runner.run
    end

    should "not run the after callbacks b/c of the halt" do
      assert_not_equal true, @handler.after_called
    end

    should "not run the handler's init and run b/c of the halt" do
      assert_not_equal true, @handler.init_bang_called
      assert_not_equal true, @handler.run_bang_called
    end

    should "return its `to_rack` value despite the halt" do
      assert_equal subject_to_rack_with_content_length, @response
    end

  end

  class RunWithAfterHaltTests < InitHandlerTests
    desc "with a handler that halts in an after callback"
    setup do
      @handler.halt_in_after = true
      @response = @runner.run
    end

    should "run the before callback despite the halt" do
      assert_equal true, @handler.before_called
    end

    should "run the handler's init and run despite the halt" do
      assert_equal true, @handler.init_bang_called
      assert_equal true, @handler.run_bang_called
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

end
