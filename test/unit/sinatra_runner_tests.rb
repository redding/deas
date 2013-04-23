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
      :halt, :render

    should "return the sinatra_call's request with #request" do
      assert_equal @fake_sinatra_call.request, subject.request
    end

    should "return the sinatra_call's response with #response" do
      assert_equal @fake_sinatra_call.response, subject.response
    end

    should "return the sinatra_call's params with #params" do
      assert_equal @fake_sinatra_call.params, subject.params
    end

    should "return the sinatra_call's settings logger with #logger" do
      assert_equal @fake_sinatra_call.settings.deas_logger, subject.logger
    end

    should "call the sinatra_call's halt with #halt" do
      return_value = catch(:halt){ subject.halt('test') }
      assert_equal 'test', return_value
    end

    should "call the sinatra_call's erb method with #render" do
      return_value = subject.render('index')

      assert_equal :web,   return_value[0]
      assert_equal :index, return_value[2]

      options = return_value[3]
      assert_instance_of Deas::Template::RenderScope, options[:scope]

      expected_locals = { :view => subject.instance_variable_get("@handler") }
      assert_equal(expected_locals, options[:locals])
    end

    should "not throw an exception with the setup or teardown methods" do
      assert_nothing_raised  {subject.setup}
      assert_nothing_raised {subject.teardown}
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
