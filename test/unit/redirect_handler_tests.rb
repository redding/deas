require 'assert'
require 'deas/redirect_handler'
require 'deas/test_helpers'

module Deas::RedirectHandler

  class BaseTests < Assert::Context
    desc "Deas::RedirectHandler"
    setup do
      @handler_class = Deas::RedirectHandler.new('/somewhere')
    end
    subject{ @handler_class }

    should have_accessors :redirect_path

    should "build a redirect handler class" do
      subject.included_modules.tap do |modules|
        assert_includes Deas::ViewHandler, modules
        assert_includes Deas::RedirectHandler::InstanceMethods, modules
      end

      assert_instance_of Proc, subject.redirect_path
      assert_equal '/somewhere', subject.redirect_path.call
    end

    should "allow passing a block instead of a static path" do
      path_proc = proc{ '/somewhere' }

      handler_class = Deas::RedirectHandler.new(&path_proc)
      assert_equal path_proc, handler_class.redirect_path
    end

  end

  class RunTests < BaseTests
    include Deas::TestHelpers

    desc "when run"

    should "redirect to the path that it was build with" do
      @response = test_runner(@handler_class).run
      assert_equal [ :redirect, "/somewhere" ], @response
    end

    should "redirect to the path returned from instance evaling the proc" do
      path_proc = proc{ params['redirect_to'] }
      handler_class = Deas::RedirectHandler.new(&path_proc)

      @response = test_runner(handler_class, {
        :params => { 'redirect_to' => '/go_here' }
      }).run
      assert_equal [ :redirect, "/go_here" ], @response
    end

  end

end
