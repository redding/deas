require 'assert'
require 'deas/view_handler'

require 'deas/template_source'
require 'rack/request'
require 'rack/response'
require 'test/support/empty_view_handler'

module Deas::ViewHandler

  class UnitTests < Assert::Context
    include Deas::ViewHandler::TestHelpers

    desc "Deas::ViewHandler"
    setup do
      @handler_class = Class.new{ include Deas::ViewHandler }
    end
    subject{ @handler_class }

    should have_imeths :layout, :layouts
    should have_imeths :before_callbacks, :after_callbacks
    should have_imeths :before_init_callbacks, :after_init_callbacks
    should have_imeths :before_run_callbacks,  :after_run_callbacks
    should have_imeths :before, :after
    should have_imeths :before_init, :after_init
    should have_imeths :before_run,  :after_run
    should have_imeths :prepend_before, :prepend_after
    should have_imeths :prepend_before_init, :prepend_after_init
    should have_imeths :prepend_before_run,  :prepend_after_run

    should "specify layouts" do
      subject.layout 'layouts/app'
      assert_equal ['layouts/app'], subject.layouts.map(&:call)

      subject.layout { 'layouts/web' }
      assert_equal ['layouts/app', 'layouts/web'], subject.layouts.map(&:call)
    end

    should "return an empty array by default using `before_callbacks`" do
      assert_equal [], subject.before_callbacks
    end

    should "return an empty array by default using `after_callbacks`" do
      assert_equal [], subject.after_callbacks
    end

    should "return an empty array by default using `before_init_callbacks`" do
      assert_equal [], subject.before_init_callbacks
    end

    should "return an empty array by default using `after_init_callbacks`" do
      assert_equal [], subject.after_init_callbacks
    end

    should "return an empty array by default using `before_run_callbacks`" do
      assert_equal [], subject.before_run_callbacks
    end

    should "return an empty array by default using `after_run_callbacks`" do
      assert_equal [], subject.after_run_callbacks
    end

  should "append a block to the before callbacks using `before`" do
    subject.before_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.before(&block)
    assert_equal block, subject.before_callbacks.last
  end

  should "append a block to the after callbacks using `after`" do
    subject.after_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.after(&block)
    assert_equal block, subject.after_callbacks.last
  end

  should "append a block to the before init callbacks using `before_init`" do
    subject.before_init_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.before_init(&block)
    assert_equal block, subject.before_init_callbacks.last
  end

  should "append a block to the after init callbacks using `after_init`" do
    subject.after_init_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.after_init(&block)
    assert_equal block, subject.after_init_callbacks.last
  end

  should "append a block to the before run callbacks using `before_run`" do
    subject.before_run_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.before_run(&block)
    assert_equal block, subject.before_run_callbacks.last
  end

  should "append a block to the after run callbacks using `after_run`" do
    subject.after_run_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.after_run(&block)
    assert_equal block, subject.after_run_callbacks.last
  end

  should "prepend a block to the before callbacks using `prepend_before`" do
    subject.before_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_before(&block)
    assert_equal block, subject.before_callbacks.first
  end

  should "prepend a block to the after callbacks using `prepend_after`" do
    subject.after_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_after(&block)
    assert_equal block, subject.after_callbacks.first
  end

  should "prepend a block to the before init callbacks using `prepend_before_init`" do
    subject.before_init_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_before_init(&block)
    assert_equal block, subject.before_init_callbacks.first
  end

  should "prepend a block to the after init callbacks using `prepend_after_init`" do
    subject.after_init_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_after_init(&block)
    assert_equal block, subject.after_init_callbacks.first
  end

  should "prepend a block to the before run callbacks using `prepend_before_run`" do
    subject.before_run_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_before_run(&block)
    assert_equal block, subject.before_run_callbacks.first
  end

  should "prepend a block to the after run callbacks using `prepend_after_run`" do
    subject.after_run_callbacks << proc{ Factory.string }
    block = Proc.new{ Factory.string }
    subject.prepend_after_run(&block)
    assert_equal block, subject.after_run_callbacks.first
  end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @runner  = test_runner(TestViewHandler)
      @handler = @runner.handler
    end
    subject{ @handler }

    should have_imeths :deas_init, :init!, :deas_run, :run!
    should have_imeths :layouts, :deas_run_callback

    should "have called `init!` and its before/after init callbacks" do
      assert_equal 1, subject.first_before_init_call_order
      assert_equal 2, subject.second_before_init_call_order
      assert_equal 3, subject.init_call_order
      assert_equal 4, subject.first_after_init_call_order
      assert_equal 5, subject.second_after_init_call_order
    end

    should "not have called `run!` and its before/after run callbacks" do
      assert_nil subject.first_before_run_call_order
      assert_nil subject.second_before_run_call_order
      assert_nil subject.run_call_order
      assert_nil subject.first_after_run_call_order
      assert_nil subject.second_after_run_call_order
    end

    should "run its callbacks with `deas_run_callback`" do
      subject.deas_run_callback 'before_run'
      assert_equal 6, subject.first_before_run_call_order
      assert_equal 7, subject.second_before_run_call_order
    end

    should "know if it is equal to another view handler" do
      handler = test_handler(TestViewHandler)
      assert_equal handler, subject

      handler = test_handler(Class.new{ include Deas::ViewHandler })
      assert_not_equal handler, subject
    end

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @handler.deas_run
    end

    should "call `run!` and it's callbacks" do
      assert_equal 6,  subject.first_before_run_call_order
      assert_equal 7,  subject.second_before_run_call_order
      assert_equal 8,  subject.run_call_order
      assert_equal 9,  subject.first_after_run_call_order
      assert_equal 10, subject.second_after_run_call_order
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

    attr_reader :first_before_init_call_order, :second_before_init_call_order
    attr_reader :first_after_init_call_order, :second_after_init_call_order
    attr_reader :first_before_run_call_order, :second_before_run_call_order
    attr_reader :first_after_run_call_order, :second_after_run_call_order
    attr_reader :init_call_order, :run_call_order

    before_init{ @first_before_init_call_order = next_call_order }
    before_init{ @second_before_init_call_order = next_call_order }

    after_init{ @first_after_init_call_order = next_call_order }
    after_init{ @second_after_init_call_order = next_call_order }

    before_run{ @first_before_run_call_order = next_call_order }
    before_run{ @second_before_run_call_order = next_call_order }

    after_run{ @first_after_run_call_order = next_call_order }
    after_run{ @second_after_run_call_order = next_call_order }

    def init!
      @init_call_order = next_call_order
    end

    def run!
      @run_call_order = next_call_order
    end

    private

    def next_call_order
      @order ||= 0
      @order += 1
    end

  end

  class LayoutsViewHandler
    include Deas::ViewHandler

    layout '1.html'
    layout { '2.html' }
    layout { "#{params['n']}.html" }

  end

end
