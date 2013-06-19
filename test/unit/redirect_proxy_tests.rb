require 'assert'
require 'deas/test_helpers'
require 'deas/redirect_proxy'

class Deas::RedirectProxy

  class BaseTests < Assert::Context
    desc "Deas::RedirectProxy"
    setup do
      @proxy = Deas::RedirectProxy.new('/somewhere')
    end
    subject{ @proxy }

    should have_readers :handler_class_name, :handler_class

    should "know its handler class name" do
      assert_equal subject.handler_class.name, subject.handler_class_name
    end

  end

  class HandlerClassTests < BaseTests
    desc "handler class"
    setup do
      @handler_class = @proxy.handler_class
    end
    subject{ @handler_class }

    should have_accessors :redirect_path
    should have_imeth :name

    should "be a view handler" do
      subject.included_modules.tap do |modules|
        assert_includes Deas::ViewHandler, modules
      end
    end

    should "know its name" do
      assert_equal 'Deas::RedirectHandler', subject.name
    end

    should "know its redirect path" do
      assert_instance_of Proc, subject.redirect_path
      assert_equal '/somewhere', subject.redirect_path.call
    end

    should "allow specifying the redir path as a block" do
      path_proc = proc{ '/somewhere' }

      handler_class = Deas::RedirectProxy.new(&path_proc).handler_class
      assert_equal path_proc, handler_class.redirect_path
      assert_equal '/somewhere', subject.redirect_path.call
    end

  end

  class RunTests < HandlerClassTests
    include Deas::TestHelpers

    desc "when run"

    should "redirect to the path that it was build with" do
      render_args = test_runner(subject).run
      assert_equal true,         render_args.redirect?
      assert_equal '/somewhere', render_args.path
    end

    should "redirect to the path returned from instance evaling the proc" do
      path_proc = proc{ params['redirect_to'] }
      handler_class = Deas::RedirectProxy.new(&path_proc).handler_class

      render_args = test_runner(handler_class, {
        :params => { 'redirect_to' => '/go_here' }
      }).run
      assert_equal true,       render_args.redirect?
      assert_equal '/go_here', render_args.path
    end

  end

end
