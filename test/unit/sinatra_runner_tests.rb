require 'assert'
require 'deas/sinatra_runner'
require 'deas/template'
require 'test/support/fake_app'
require 'test/support/view_handlers'

class Deas::SinatraRunner

  class BaseTests < Assert::Context
    desc "Deas::SinatraRunner"
    setup do
      @fake_sinatra_call = FakeApp.new
      @runner = Deas::SinatraRunner.new(FlagViewHandler, @fake_sinatra_call)
    end
    subject{ @runner }

    should have_instance_methods :run, :request, :response, :params, :logger,
      :halt, :render, :session, :redirect, :redirect_to

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

    should "render the template with a :view local and the handler layouts with #render" do
      exp_handler = FlagViewHandler.new(subject)
      exp_layouts = FlagViewHandler.layouts
      exp_result = Deas::Template.new(@fake_sinatra_call, 'index', {
        :locals => { :view => exp_handler },
        :layout => exp_layouts
      }).render

      assert_equal exp_result, subject.render('index')
    end

    should "call the sinatra_call's redirect method with #redirect" do
      return_value = catch(:halt){ subject.redirect('http://google.com') }
      expected = [ 302, { 'Location' => 'http://google.com' } ]

      assert_equal expected, return_value
    end

    should "call the sinatra_call's redirect and to methods with #redirect_to" do
      return_value = catch(:halt){ subject.redirect_to('/somewhere') }
      expected = [ 302, { 'Location' => "http://test.local/somewhere" } ]

      assert_equal expected, return_value
    end

  end

  class RunTests < BaseTests
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

end
