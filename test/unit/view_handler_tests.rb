require 'assert'
require 'deas/test_helpers'
require 'deas/view_handler'
require 'test/support/view_handlers'

module Deas::ViewHandler

  class BaseTests < Assert::Context
    include Deas::TestHelpers

    desc "Deas::ViewHandler"
    setup do
      @handler = test_runner(TestViewHandler).handler
    end
    subject{ @handler }

    should have_instance_methods :init, :init!, :run, :run!
    should have_class_methods :before,      :before_callbacks
    should have_class_methods :after,       :after_callbacks
    should have_class_methods :before_init, :before_init_callbacks
    should have_class_methods :after_init,  :after_init_callbacks
    should have_class_methods :before_run,  :before_run_callbacks
    should have_class_methods :after_run,   :after_run_callbacks
    should have_class_methods :layout, :layouts

    should "raise a NotImplementedError if run! is not overwritten" do
      assert_raises(NotImplementedError){ subject.run! }
    end

    should "store procs in #before_callbacks with #before" do
      before_proc = proc{ }
      TestViewHandler.before(&before_proc)

      assert_includes before_proc, TestViewHandler.before_callbacks
    end

    should "store procs in #after_callbacks with #after" do
      after_proc = proc{ }
      TestViewHandler.after(&after_proc)

      assert_includes after_proc, TestViewHandler.after_callbacks
    end

    should "store procs in #before_init_callbacks with #before_init" do
      before_init_proc = proc{ }
      TestViewHandler.before_init(&before_init_proc)

      assert_includes before_init_proc, TestViewHandler.before_init_callbacks
    end

    should "store procs in #after_init_callbacks with #after_init" do
      after_init_proc = proc{ }
      TestViewHandler.after_init(&after_init_proc)

      assert_includes after_init_proc, TestViewHandler.after_init_callbacks
    end

    should "store procs in #before_run_callbacks with #before_run" do
      before_run_proc = proc{ }
      TestViewHandler.before_run(&before_run_proc)

      assert_includes before_run_proc, TestViewHandler.before_run_callbacks
    end

    should "store procs in #after_run_callbacks with #after_run" do
      after_run_proc = proc{ }
      TestViewHandler.after_run(&after_run_proc)

      assert_includes after_run_proc, TestViewHandler.after_run_callbacks
    end

    should "allow specifying the layouts using #layout or #layouts" do
      handler_class = Class.new{ include Deas::ViewHandler }

      handler_class.layout 'layouts/app'
      assert_equal [ 'layouts/app' ], handler_class.layouts

      handler_class.layouts 'layouts/web', 'layouts/search'
      assert_equal [ 'layouts/web', 'layouts/search' ], handler_class.layouts
    end

    should "be able to render templates" do
      return_value = test_runner(RenderViewHandler).run
      assert_equal "my_template",        return_value[0]
      assert_equal({ :some => :option }, return_value[1])
    end

  end

  class WithMethodFlagsTests < BaseTests
    setup do
      @handler = test_runner(FlagViewHandler).handler
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
