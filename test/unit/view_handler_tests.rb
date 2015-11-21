require 'assert'
require 'deas/view_handler'

require 'deas/template_source'
require 'rack/request'
require 'rack/response'
require 'test/support/view_handlers'

module Deas::ViewHandler

  class UnitTests < Assert::Context
    include Deas::ViewHandler::TestHelpers

    desc "Deas::ViewHandler"
    setup do
      @handler_class = TestViewHandler
    end
    subject{ @handler_class }

    should have_imeths :layout, :layouts
    should have_imeths :before, :prepend_before, :before_callbacks
    should have_imeths :after,  :prepend_after,  :after_callbacks
    should have_imeths :before_init, :prepend_before_init, :before_init_callbacks
    should have_imeths :after_init,  :prepend_after_init,  :after_init_callbacks
    should have_imeths :before_run,  :prepend_before_run,  :before_run_callbacks
    should have_imeths :after_run,   :prepend_after_run,   :after_run_callbacks

    should "specify layouts" do
      subject.layout 'layouts/app'
      assert_equal ['layouts/app'], subject.layouts.map(&:call)

      subject.layout { 'layouts/web' }
      assert_equal ['layouts/app', 'layouts/web'], subject.layouts.map(&:call)
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @runner  = test_runner(@handler_class)
      @handler = @runner.handler
    end
    subject{ @handler }

    should have_imeths :deas_init, :init!, :deas_run, :run!
    should have_imeths :layouts, :deas_run_callback

    should "have called `init!` and it's callbacks" do
      assert_equal true, subject.before_init_called
      assert_equal true, subject.second_before_init_called
      assert_equal true, subject.init_bang_called
      assert_equal true, subject.after_init_called
    end

    should "not have called `run!` or it's callbacks when initialized" do
      assert_nil subject.before_run_called
      assert_nil subject.run_bang_called
      assert_nil subject.after_run_called
    end

    should "run its callbacks with `deas_run_callback`" do
      subject.deas_run_callback 'before_run'
      assert_equal true, subject.before_run_called
    end

    should "know if it is equal to another view handler" do
      handler = test_handler(@handler_class)
      assert_equal handler, subject

      handler = test_handler(Class.new{ include Deas::ViewHandler })
      assert_not_equal handler, subject
    end

  end

  class RunTests < InitTests
    desc "and run"

    should "call `run!` and it's callbacks" do
      subject.deas_run
      assert_equal true, subject.before_run_called
      assert_equal true, subject.run_bang_called
      assert_equal true, subject.after_run_called
    end

  end

  class PrivateHelpersTests < InitTests
    setup do
      @something = Factory.string
      @args      = (Factory.integer(3)+1).times.map{ Factory.string }
      @block     = proc{}
    end

    should "call to the runner for its logger" do
      stub_runner_with_something_for(:logger)
      assert_equal @runner.logger, subject.instance_eval{ logger }
    end

    should "call to the runner for its router" do
      stub_runner_with_something_for(:router)
      assert_equal @runner.router, subject.instance_eval{ router }
    end

    should "call to the runner for its request" do
      stub_runner_with_something_for(:request)
      assert_equal @runner.request, subject.instance_eval{ request }
    end

    should "call to the runner for its session" do
      stub_runner_with_something_for(:session)
      assert_equal @runner.session, subject.instance_eval{ session }
    end

    should "call to the runner for its params" do
      stub_runner_with_something_for(:params)
      assert_equal @runner.params, subject.instance_eval{ params }
    end

    should "call to the runner for its status helper" do
      capture_runner_meth_args_for(:status)
      exp_args = @args
      subject.instance_eval{ status(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its headers helper" do
      capture_runner_meth_args_for(:headers)
      exp_args = @args
      subject.instance_eval{ headers(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its body helper" do
      capture_runner_meth_args_for(:body)
      exp_args = @args
      subject.instance_eval{ body(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its content type helper" do
      capture_runner_meth_args_for(:content_type)
      exp_args = @args
      subject.instance_eval{ content_type(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its halt helper" do
      capture_runner_meth_args_for(:halt)
      exp_args = @args
      subject.instance_eval{ halt(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its redirect helper" do
      capture_runner_meth_args_for(:redirect)
      exp_args = @args
      subject.instance_eval{ redirect(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its send file helper" do
      capture_runner_meth_args_for(:send_file)
      exp_args = @args
      subject.instance_eval{ send_file(*exp_args) }

      assert_equal exp_args, @meth_args
      assert_nil @meth_block
    end

    should "call to the runner for its render helper" do
      capture_runner_meth_args_for(:render)
      exp_args, exp_block = @args, @block
      subject.instance_eval{ render(*exp_args, &exp_block) }

      assert_equal exp_args,  @meth_args
      assert_equal exp_block, @meth_block
    end

    should "call to the runner for its source render helper" do
      capture_runner_meth_args_for(:source_render)
      exp_args, exp_block = @args, @block
      subject.instance_eval{ source_render(*exp_args, &exp_block) }

      assert_equal exp_args,  @meth_args
      assert_equal exp_block, @meth_block
    end

    should "call to the runner for its partial helper" do
      capture_runner_meth_args_for(:partial)
      exp_args, exp_block = @args, @block
      subject.instance_eval{ partial(*exp_args, &exp_block) }

      assert_equal exp_args,  @meth_args
      assert_equal exp_block, @meth_block
    end

    should "call to the runner for its source partial helper" do
      capture_runner_meth_args_for(:source_partial)
      exp_args, exp_block = @args, @block
      subject.instance_eval{ source_partial(*exp_args, &exp_block) }

      assert_equal exp_args,  @meth_args
      assert_equal exp_block, @meth_block
    end

    private

    def stub_runner_with_something_for(meth)
      Assert.stub(@runner, meth){ @something }
    end

    def capture_runner_meth_args_for(meth)
      Assert.stub(@runner, meth) do |*args, &block|
        @meth_args  = args
        @meth_block = block
      end
    end

  end

  class InitLayoutsTests < UnitTests
    desc "when init with layouts"
    setup do
      @params = { 'n' => Factory.integer }
      @runner  = test_runner(LayoutsViewHandler, :params => @params)
      @handler = @runner.handler
    end
    subject{ @handler }

    should "build its layouts by instance eval'ing its class layout procs" do
      exp = subject.class.layouts.map{ |proc| subject.instance_eval(&proc) }
      assert_equal exp, subject.layouts
    end

  end

  class CallbackTests < UnitTests
    setup do
      @proc1 = proc{ '1' }
      @proc2 = proc{ '2' }
      @handler = Class.new{ include Deas::ViewHandler }
    end

    should "append before procs" do
      @handler.before(&@proc1); @handler.before(&@proc2)
      assert_equal @proc1, @handler.before_callbacks.first
      assert_equal @proc2, @handler.before_callbacks.last
    end

    should "prepend before procs" do
      @handler.prepend_before(&@proc1); @handler.prepend_before(&@proc2)
      assert_equal @proc2, @handler.before_callbacks.first
      assert_equal @proc1, @handler.before_callbacks.last
    end

    should "append after procs" do
      @handler.after(&@proc1); @handler.after(&@proc2)
      assert_equal @proc1, @handler.after_callbacks.first
      assert_equal @proc2, @handler.after_callbacks.last
    end

    should "prepend after procs" do
      @handler.prepend_after(&@proc1); @handler.prepend_after(&@proc2)
      assert_equal @proc2, @handler.after_callbacks.first
      assert_equal @proc1, @handler.after_callbacks.last
    end

    should "append before init procs" do
      @handler.before_init(&@proc1); @handler.before_init(&@proc2)
      assert_equal @proc1, @handler.before_init_callbacks.first
      assert_equal @proc2, @handler.before_init_callbacks.last
    end

    should "prepend before init procs" do
      @handler.prepend_before_init(&@proc1); @handler.prepend_before_init(&@proc2)
      assert_equal @proc2, @handler.before_init_callbacks.first
      assert_equal @proc1, @handler.before_init_callbacks.last
    end

    should "append after init procs" do
      @handler.after_init(&@proc1); @handler.after_init(&@proc2)
      assert_equal @proc1, @handler.after_init_callbacks.first
      assert_equal @proc2, @handler.after_init_callbacks.last
    end

    should "prepend after init procs" do
      @handler.prepend_after_init(&@proc1); @handler.prepend_after_init(&@proc2)
      assert_equal @proc2, @handler.after_init_callbacks.first
      assert_equal @proc1, @handler.after_init_callbacks.last
    end

    should "append before run procs" do
      @handler.before_run(&@proc1); @handler.before_run(&@proc2)
      assert_equal @proc1, @handler.before_run_callbacks.first
      assert_equal @proc2, @handler.before_run_callbacks.last
    end

    should "prepend before run procs" do
      @handler.prepend_before_run(&@proc1); @handler.prepend_before_run(&@proc2)
      assert_equal @proc2, @handler.before_run_callbacks.first
      assert_equal @proc1, @handler.before_run_callbacks.last
    end

    should "append after run procs" do
      @handler.after_run(&@proc1); @handler.after_run(&@proc2)
      assert_equal @proc1, @handler.after_run_callbacks.first
      assert_equal @proc2, @handler.after_run_callbacks.last
    end

    should "prepend after run procs" do
      @handler.prepend_after_run(&@proc1); @handler.prepend_after_run(&@proc2)
      assert_equal @proc2, @handler.after_run_callbacks.first
      assert_equal @proc1, @handler.after_run_callbacks.last
    end

  end

  class TestHelpersTests < UnitTests
    desc "TestHelpers"
    setup do
      context_class = Class.new{ include Deas::ViewHandler::TestHelpers }
      @context = context_class.new
    end
    subject{ @context }

    should have_imeths :test_runner, :test_handler

    should "build a test runner for a given handler class" do
      runner  = subject.test_runner(@handler_class)

      assert_kind_of ::Deas::TestRunner, runner
      assert_kind_of Rack::Request,  runner.request
      assert_equal runner.request.session, runner.session
    end

    should "return an initialized handler instance" do
      handler = subject.test_handler(@handler_class)
      assert_kind_of @handler_class, handler

      exp = subject.test_runner(@handler_class).handler
      assert_equal exp, handler
    end

  end

  class TestViewHandler
    include Deas::ViewHandler

    attr_reader :before_called, :after_called
    attr_reader :before_init_called, :second_before_init_called
    attr_reader :init_bang_called, :after_init_called
    attr_reader :before_run_called, :run_bang_called, :after_run_called

    before{ @before_called = true }
    after{  @after_called  = true }

    before_init{ @before_init_called        = true }
    before_init{ @second_before_init_called = true }
    after_init{  @after_init_called         = true }
    before_run{  @before_run_called         = true }
    after_run{   @after_run_called          = true }

    def init!; @init_bang_called = true; end
    def run!;  @run_bang_called = true;  end

  end

  class LayoutsViewHandler
    include Deas::ViewHandler

    layout '1.html'
    layout { '2.html' }
    layout { "#{params['n']}.html" }

  end

end
