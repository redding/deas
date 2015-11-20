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

  end

  class RunTests < InitHandlerTests
    desc "and run"
    setup do
      @response_value = @runner.run
      @handler = @runner.instance_variable_get("@handler")
    end
    subject{ @handler }

    should "run the before and after hooks" do
      assert_equal true, subject.before_called
      assert_equal true, subject.after_called
    end

    should "run the handler's init and run" do
      assert_equal true, subject.init_bang_called
      assert_equal true, subject.run_bang_called
    end

    should "use the handler's run! return value as its response value" do
      assert_equal true, @response_value
    end

  end

  class NormalizedParamsTests < UnitTests
    desc "NormalizedParams"
    setup do
      @norm_params_class = Deas::SinatraRunner::NormalizedParams
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
