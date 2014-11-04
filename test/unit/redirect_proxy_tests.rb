require 'assert'
require 'deas/redirect_proxy'

require 'deas/test_helpers'

class Deas::RedirectProxy

  class UnitTests < Assert::Context
    desc "Deas::RedirectProxy"
    setup do
      @proxy = Deas::RedirectProxy.new('/somewhere')
    end
    subject{ @proxy }

    should have_readers :handler_class_name, :handler_class
    should have_imeths :validate!

    should "know its handler class name" do
      assert_equal subject.handler_class.name, subject.handler_class_name
    end

  end

  class HandlerClassTests < UnitTests
    include Deas::TestHelpers

    desc "redir handler class"
    setup do
      @handler_class = @proxy.handler_class
    end
    subject{ @handler_class }

    should have_accessor :redirect_path
    should have_imeth :name

    should "be a view handler" do
      subject.included_modules.tap do |modules|
        assert_includes Deas::ViewHandler, modules
      end
    end

    should "know its name" do
      assert_equal 'Deas::RedirectHandler', subject.name
    end

    should "store its redirect path as a proc" do
      assert_kind_of Proc, subject.redirect_path

      url = Deas::Url.new(:some_thing, '/:some/:thing')
      handler_class = Deas::RedirectProxy.new(url).handler_class
      assert_kind_of Proc, handler_class.redirect_path

      path_proc = proc{ '/somewhere' }
      handler_class = Deas::RedirectProxy.new(&path_proc).handler_class
      assert_kind_of Proc, handler_class.redirect_path
    end

  end

  class HandlerTests < HandlerClassTests
    desc "redir handler instance"
    setup do
      @handler = test_handler(@handler_class)
    end
    subject{ @handler }

    should have_reader :redirect_path

    should "know its redir path if from a path string" do
      assert_equal '/somewhere', subject.redirect_path
    end

    should "know its redir path if from Url" do
      url = Deas::Url.new(:some_thing, '/:some/:thing')
      handler_class = Deas::RedirectProxy.new(url).handler_class
      handler = test_handler(handler_class, {
        :params => { 'some' => 'a', 'thing' => 'goose' }
      })

      assert_equal '/a/goose', handler.redirect_path
    end

    should "know its redir path if from a block" do
      handler_class = Deas::RedirectProxy.new(&proc{'/from-block-arg'}).handler_class
      handler = test_handler(handler_class)

      assert_equal '/from-block-arg', handler.redirect_path
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
