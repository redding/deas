require 'assert'
require 'deas/respond_with_proxy'

require 'deas/handler_proxy'
require 'deas/url'
require 'deas/view_handler'

class Deas::RespondWithProxy

  class UnitTests < Assert::Context
    desc "Deas::RespondWithProxy"
    setup do
      @status  = Factory.integer
      @headers = { Factory.string => Factory.string }
      @body    = [Factory.string]
      @proxy    = Deas::RespondWithProxy.new([@status, @headers, @body])
    end
    subject{ @proxy }

    should "be a HandlerProxy" do
      assert_kind_of Deas::HandlerProxy, subject
    end

  end

  class HandlerClassTests < UnitTests
    include Deas::ViewHandler::TestHelpers

    desc "handler class"
    setup do
      @handler_class = @proxy.handler_class
    end
    subject{ @handler_class }

    should have_accessor :halt_args
    should have_imeth :name

    should "be a view handler" do
      subject.included_modules.tap do |modules|
        assert_includes Deas::ViewHandler, modules
      end
    end

    should "store the args to halt with" do
      assert_equal [@status, @headers, @body], subject.halt_args
    end

    should "know its name" do
      assert_equal 'Deas::RespondWithHandler', subject.name
    end

  end

  class HandlerTests < HandlerClassTests
    desc "handler instance"
    setup do
      @handler = test_handler(@handler_class)
    end
    subject{ @handler }

    should have_reader :halt_args

    should "know its halt args" do
      assert_equal [@status, @headers, @body], subject.halt_args
    end

  end

  class RunTests < HandlerClassTests
    desc "when run"
    setup do
      @runner   = test_runner(@handler_class)
      @handler  = @runner.handler
      @response = @runner.run
    end
    subject{ @response }

    should "halt and respond with the halt args" do
      assert_equal @status,  subject.status
      assert_equal @headers, subject.headers
      assert_equal @body,    subject.body
    end

  end

end
