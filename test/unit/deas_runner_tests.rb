require 'assert'
require 'deas/deas_runner'

require 'deas/runner'
require 'test/support/normalized_params_spy'
require 'test/support/view_handlers'

class Deas::DeasRunner

  class UnitTests < Assert::Context
    desc "Deas::DeasRunner"
    setup do
      @runner_class = Deas::DeasRunner
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

      @runner = @runner_class.new(DeasRunnerViewHandler, :params => @params)
    end
    subject{ @runner }

    should have_imeths :run

    should "super its params arg" do
      assert_equal @params, subject.params
    end

    should "call to normalize its params" do
      assert_equal @params, @norm_params_spy.params
      assert_true @norm_params_spy.value_called
    end

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @return_value = @runner.run
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

    should "return the handler's run! return value" do
      assert_equal true, @return_value
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

  class RenderSetupTests < InitTests
    setup do
      @template_name = Factory.path
      @locals = { Factory.string => Factory.string }
    end

  end

  class RenderTests < RenderSetupTests
    desc "render method"
    setup do
      @render_args = nil
      Assert.stub(@runner.template_source, :render){ |*args| @render_args = args }
    end

    should "call to its template source render method" do
      subject.render(@template_name, @locals)
      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @render_args

      subject.render(@template_name)
      exp = [@template_name, subject.handler, {}]
      assert_equal exp, @render_args
    end

  end

  class PartialTests < RenderSetupTests
    desc "partial method"
    setup do
      @partial_args = nil
      Assert.stub(@runner.template_source, :partial){ |*args| @partial_args = args }
    end

    should "call to its template source partial method" do
      subject.partial(@template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @partial_args

      subject.partial(@template_name)
      exp = [@template_name, {}]
      assert_equal exp, @partial_args
    end

  end

end
