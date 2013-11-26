require 'assert'
require 'test/support/fake_sinatra_call'
require 'test/support/view_handlers'
require 'deas/template'
require 'deas/sinatra_runner'

class Deas::SinatraRunner

  class UnitTests < Assert::Context
    desc "Deas::SinatraRunner"
    setup do
      @fake_sinatra_call = FakeSinatraCall.new
      @runner = Deas::SinatraRunner.new(FlagViewHandler, @fake_sinatra_call)
    end
    subject{ @runner }

    should have_imeths :run, :request, :response, :params, :logger, :session
    should have_imeths :halt, :redirect, :content_type, :status, :render

    should "return the sinatra_call's request with #request" do
      assert_equal @fake_sinatra_call.request, subject.request
    end

    should "return the sinatra_call's response with #response" do
      assert_equal @fake_sinatra_call.response, subject.response
    end

    should "return the sinatra_call's params with #params" do
      assert_equal @fake_sinatra_call.params, subject.params
    end

    should "return the sinatra_call's session with #session" do
      assert_equal @fake_sinatra_call.session, subject.session
    end

    should "return the sinatra_call's settings logger with #logger" do
      assert_equal @fake_sinatra_call.settings.deas_logger, subject.logger
    end

    should "call the sinatra_call's halt with #halt" do
      return_value = catch(:halt){ subject.halt('test') }
      assert_equal [ 'test' ], return_value
    end

    should "call the sinatra_call's redirect method with #redirect" do
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

    should "call the sinatra_call's status to set the response status" do
      exp_headers = {
        'a-header' => 'some value',
        'other'    => 'other'
      }
      assert_equal [exp_headers], subject.headers(exp_headers)
    end

    should "render the template with a :view local and the handler layouts with #render" do
      exp_handler = FlagViewHandler.new(subject)
      exp_layouts = FlagViewHandler.layouts
      exp_result = Deas::Template.new(@fake_sinatra_call, 'index', {
        :locals => { :view => exp_handler },
        :layout => exp_layouts
      }).render

      assert_equal exp_result, subject.render('index')
    end

  end

  class RunTests < UnitTests
    desc "run"
    setup do
      @return_value = @runner.run
      @handler = @runner.instance_variable_get("@handler")
    end
    subject{ @handler }

    should "run the before and after hooks" do
      assert_equal true, subject.before_hook_called
      assert_equal true, subject.after_hook_called
    end

    should "run the handler's init and run" do
      assert_equal true, subject.init_bang_called
      assert_equal true, subject.run_bang_called
    end

    should "return the handler's run! return value" do
      assert_equal true, @return_value
    end

  end

  class ParamsTests < UnitTests
    desc "normalizing params"

    should "convert any non-string hash keys to string keys" do
      exp_params = {
        'a' => 'aye',
        'b' => 'bee',
        'attachment' => {
          'tempfile' => 'a-file',
          'content_type' => 'whatever'
        },
        'attachments' => [
          { 'tempfile' => 'a-file' },
          { 'tempfile' => 'b-file' }
        ]
      }
      assert_equal exp_params, runner_params({
        :a  => 'aye',
        'b' => 'bee',
        'attachment' => {
          :tempfile => 'a-file',
          :content_type => 'whatever'
        },
        'attachments' => [
          { :tempfile  => 'a-file' },
          { 'tempfile' => 'b-file' }
        ]
      })
    end

    private

    def runner_params(params)
      @fake_sinatra_call.params = params
      Deas::SinatraRunner.new(FlagViewHandler, @fake_sinatra_call).params
    end

  end

end
