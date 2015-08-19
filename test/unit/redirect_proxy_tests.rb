require 'assert'
require 'deas/redirect_proxy'

require 'deas/handler_proxy'
require 'deas/test_helpers'
require 'deas/url'
require 'deas/view_handler'

class Deas::RedirectProxy

  class UnitTests < Assert::Context
    desc "Deas::RedirectProxy"
    setup do
      @base_url = Factory.url
      @router   = Deas::Router.new
      @proxy    = Deas::RedirectProxy.new(@router, '/somewhere')
    end
    subject{ @proxy }

    should "be a HandlerProxy" do
      assert_kind_of Deas::HandlerProxy, subject
    end

  end

  class HandlerClassTests < UnitTests
    include Deas::TestHelpers

    desc "handler class"
    setup do
      @handler_class = @proxy.handler_class
    end
    subject{ @handler_class }

    should have_accessor :router, :redirect_path
    should have_imeth :name

    should "be a view handler" do
      subject.included_modules.tap do |modules|
        assert_includes Deas::ViewHandler, modules
      end
    end

    should "store the given router" do
      assert_equal @router, subject.router
    end

    should "store its redirect path as a proc" do
      assert_kind_of Proc, subject.redirect_path

      url = Deas::Url.new(:some_thing, '/:some/:thing')
      handler_class = Deas::RedirectProxy.new(@router, url).handler_class
      assert_kind_of Proc, handler_class.redirect_path

      path_proc = proc{ '/somewhere' }
      handler_class = Deas::RedirectProxy.new(@router, &path_proc).handler_class
      assert_kind_of Proc, handler_class.redirect_path
    end

    should "know its name" do
      assert_equal 'Deas::RedirectHandler', subject.name
    end

  end

  class HandlerTests < HandlerClassTests
    desc "handler instance"
    setup do
      @handler = test_handler(@handler_class)
    end
    subject{ @handler }

    should have_reader :redirect_path

    should "know its redir path if from a path string" do
      exp_path = '/somewhere'
      assert_equal exp_path, subject.redirect_path

      @router.base_url(@base_url)
      handler = test_handler(@handler_class)
      exp = @router.prepend_base_url(exp_path)
      assert_equal exp, handler.redirect_path
    end

    should "know its redir path if from Url" do
      url = Deas::Url.new(:some_thing, '/:some/:thing')
      handler_class = Deas::RedirectProxy.new(@router, url).handler_class
      handler = test_handler(handler_class, {
        :params => { 'some' => 'a', 'thing' => 'goose' }
      })

      exp_path = '/a/goose'
      assert_equal exp_path, handler.redirect_path

      @router.base_url(@base_url)
      handler = test_handler(handler_class, {
        :params => { 'some' => 'a', 'thing' => 'goose' }
      })
      exp = @router.prepend_base_url(exp_path)
      assert_equal exp, handler.redirect_path
    end

    should "know its redir path if from a block" do
      path_proc = proc{ '/from-block-arg' }
      handler_class = Deas::RedirectProxy.new(@router, &path_proc).handler_class
      handler = test_handler(handler_class)

      exp_path = '/from-block-arg'
      assert_equal exp_path , handler.redirect_path

      @router.base_url(@base_url)
      handler = test_handler(handler_class)
      exp = @router.prepend_base_url(exp_path)
      assert_equal exp, handler.redirect_path
    end

  end

  class RunTests < HandlerClassTests
    desc "when run"
    setup do
      @runner = test_runner(@handler_class)
      @handler = @runner.handler
      @render_args = @runner.run
    end

    should "redirect to the handler's redirect path" do
      assert @render_args.redirect?
      assert_equal @handler.redirect_path, @render_args.path
    end

  end

end
