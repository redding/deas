require 'assert'
require 'deas/test_helpers'
require 'deas/view_handler'
require 'test/support/view_handlers'

module Deas::ViewHandler

  class BaseTests < Assert::Context
    include Deas::TestHelpers

    desc "Deas::ViewHandler"
    setup do
      @handler = test_handler(TestViewHandler)
    end
    subject{ @handler }

    should have_imeths :init, :init!, :run, :run!
    should have_cmeths :layout, :layouts
    should have_cmeths :before, :prepend_before, :before_callbacks
    should have_cmeths :after,  :prepend_after,  :after_callbacks
    should have_cmeths :before_init, :prepend_before_init, :before_init_callbacks
    should have_cmeths :after_init,  :prepend_after_init,  :after_init_callbacks
    should have_cmeths :before_run,  :prepend_before_run,  :before_run_callbacks
    should have_cmeths :after_run,   :prepend_after_run,   :after_run_callbacks

    should "raise a NotImplementedError if run! is not overwritten" do
      assert_raises(NotImplementedError){ subject.run! }
    end

    should "be able to render templates" do
      return_value = test_runner(RenderViewHandler).run
      assert_equal "my_template",        return_value[0]
      assert_equal({ :some => :option }, return_value[1])
    end

    should "allow specifying the layouts using #layout or #layouts" do
      handler_class = Class.new{ include Deas::ViewHandler }

      handler_class.layout 'layouts/app'
      assert_equal [ 'layouts/app' ], handler_class.layouts

      handler_class.layouts 'layouts/web', 'layouts/search'
      assert_equal [ 'layouts/web', 'layouts/search' ], handler_class.layouts
    end

  end

  class CallbackTests < BaseTests
    desc "callbacks"
    setup do
      @proc1 = proc{ '1' }
      @proc2 = proc{ '2' }
      @handler = Class.new{ include Deas::ViewHandler }
    end

    should "append procs in #before_callbacks with #before" do
      @handler.before(&@proc1); @handler.before(&@proc2)
      assert_equal @proc1, @handler.before_callbacks.first
      assert_equal @proc2, @handler.before_callbacks.last
    end

    should "prepend procs in #before_callbacks with #before" do
      @handler.prepend_before(&@proc1); @handler.prepend_before(&@proc2)
      assert_equal @proc2, @handler.before_callbacks.first
      assert_equal @proc1, @handler.before_callbacks.last
    end

    should "append procs in #after_callbacks with #after" do
      @handler.after(&@proc1); @handler.after(&@proc2)
      assert_equal @proc1, @handler.after_callbacks.first
      assert_equal @proc2, @handler.after_callbacks.last
    end

    should "prepend procs in #after_callbacks with #before" do
      @handler.prepend_after(&@proc1); @handler.prepend_after(&@proc2)
      assert_equal @proc2, @handler.after_callbacks.first
      assert_equal @proc1, @handler.after_callbacks.last
    end

    should "append procs in #before_init_callbacks with #before_init" do
      @handler.before_init(&@proc1); @handler.before_init(&@proc2)
      assert_equal @proc1, @handler.before_init_callbacks.first
      assert_equal @proc2, @handler.before_init_callbacks.last
    end

    should "prepend procs in #before_init_callbacks with #before" do
      @handler.prepend_before_init(&@proc1); @handler.prepend_before_init(&@proc2)
      assert_equal @proc2, @handler.before_init_callbacks.first
      assert_equal @proc1, @handler.before_init_callbacks.last
    end

    should "append procs in #after_init_callbacks with #after_init" do
      @handler.after_init(&@proc1); @handler.after_init(&@proc2)
      assert_equal @proc1, @handler.after_init_callbacks.first
      assert_equal @proc2, @handler.after_init_callbacks.last
    end

    should "prepend procs in #after_init_callbacks with #before" do
      @handler.prepend_after_init(&@proc1); @handler.prepend_after_init(&@proc2)
      assert_equal @proc2, @handler.after_init_callbacks.first
      assert_equal @proc1, @handler.after_init_callbacks.last
    end

    should "append procs in #before_run_callbacks with #before_run" do
      @handler.before_run(&@proc1); @handler.before_run(&@proc2)
      assert_equal @proc1, @handler.before_run_callbacks.first
      assert_equal @proc2, @handler.before_run_callbacks.last
    end

    should "prepend procs in #before_run_callbacks with #before" do
      @handler.prepend_before_run(&@proc1); @handler.prepend_before_run(&@proc2)
      assert_equal @proc2, @handler.before_run_callbacks.first
      assert_equal @proc1, @handler.before_run_callbacks.last
    end

    should "append procs in #after_run_callbacks with #after_run" do
      @handler.after_run(&@proc1); @handler.after_run(&@proc2)
      assert_equal @proc1, @handler.after_run_callbacks.first
      assert_equal @proc2, @handler.after_run_callbacks.last
    end

    should "prepend procs in #after_run_callbacks with #before" do
      @handler.prepend_after_run(&@proc1); @handler.prepend_after_run(&@proc2)
      assert_equal @proc2, @handler.after_run_callbacks.first
      assert_equal @proc1, @handler.after_run_callbacks.last
    end

  end

  class WithMethodFlagsTests < BaseTests
    setup do
      @handler = test_handler(FlagViewHandler)
    end

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

    should "call `run!` and it's callbacks when it's `run`" do
      subject.run

      assert_equal true, subject.before_run_called
      assert_equal true, subject.run_bang_called
      assert_equal true, subject.after_run_called
    end

  end

  class HaltTests < BaseTests
    desc "halt"

    should "return a response with the status code and the passed data" do
      runner = test_runner(HaltViewHandler, :params => {
        'code'    => 200,
        'headers' => { 'Content-Type' => 'text/plain' },
        'body'    => 'test halting'
      })
      runner.run

      assert_equal 200,                                runner.return_value[0]
      assert_equal({ 'Content-Type' => 'text/plain' }, runner.return_value[1])
      assert_equal 'test halting',                     runner.return_value[2]
    end

  end

end
