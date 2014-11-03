require 'assert'
require 'deas/sinatra_runner'

require 'deas/runner'
require 'deas/template'
require 'test/support/fake_sinatra_call'
require 'test/support/normalized_params_spy'
require 'test/support/view_handlers'

class Deas::SinatraRunner

  class UnitTests < Assert::Context
    desc "Deas::SinatraRunner"
    setup do
      @runner_class = Deas::SinatraRunner
    end
    subject{ @runner_class }

    should "be a Runner" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @params = { 'value' => '1' }
      @norm_params_spy = Deas::Runner::NormalizedParamsSpy.new
      Assert.stub(NormalizedParams, :new){ |p| @norm_params_spy.new(p) }

      @fake_sinatra_call = FakeSinatraCall.new
      @runner = @runner_class.new(SinatraRunnerViewHandler, @fake_sinatra_call)
    end
    subject{ @runner }

    should have_imeths :run

    should "get its settings from the sinatra call" do
      assert_equal @fake_sinatra_call.request,         subject.request
      assert_equal @fake_sinatra_call.response,        subject.response
      assert_equal @fake_sinatra_call.params,          subject.params
      assert_equal @fake_sinatra_call.settings.logger, subject.logger
      assert_equal @fake_sinatra_call.settings.router, subject.router
      assert_equal @fake_sinatra_call.session,         subject.session
    end

    should "call to normalize its params" do
      assert_equal @fake_sinatra_call.params, @norm_params_spy.params
      assert_true @norm_params_spy.value_called
    end

    should "call the sinatra_call's halt with" do
      return_value = catch(:halt){ subject.halt('test') }
      assert_equal [ 'test' ], return_value
    end

    should "call the sinatra_call's redirect method with" do
      return_value = catch(:halt){ subject.redirect('http://google.com') }
      expected = [ 302, { 'Location' => 'http://google.com' } ]

      assert_equal expected, return_value
    end

    should "call the sinatra_call's content_type method using the default_charset" do
      expected = @fake_sinatra_call.content_type('text/plain', :charset => 'utf-8')
      assert_equal expected, subject.content_type('text/plain')

      expected = @fake_sinatra_call.content_type('text/plain', :charset => 'latin1')
      assert_equal expected, subject.content_type('text/plain', :charset => 'latin1')
    end

    should "call the sinatra_call's status to set the response status" do
      assert_equal [422], subject.status(422)
    end

    should "call the sinatra_call's headers to set the response headers" do
      exp_headers = {
        'a-header' => 'some value',
        'other'    => 'other'
      }
      assert_equal [exp_headers], subject.headers(exp_headers)
    end

    should "render the template with :view/:logger locals and the handler layouts" do
      exp_handler = SinatraRunnerViewHandler.new(subject)
      exp_layouts = SinatraRunnerViewHandler.layouts
      exp_result = Deas::Template.new(@fake_sinatra_call, 'index', {
        :locals => {
          :view => exp_handler,
          :logger => @runner.logger
        },
        :layout => exp_layouts
      }).render

      assert_equal exp_result, subject.render('index')
    end

    should "call the sinatra_call's send_file to set the send files" do
      block_called = false
      args = subject.send_file('a/file', {:some => 'opts'}, &proc{ block_called = true })
      assert_equal 'a/file', args.file_path
      assert_equal({:some => 'opts'}, args.options)
      assert_true block_called
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

end
