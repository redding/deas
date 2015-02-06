require 'assert'
require 'deas/test_helpers'

require 'rack/request'
require 'rack/response'
require 'deas/view_handler'

module Deas::TestHelpers

  class UnitTests < Assert::Context
    desc "Deas::TestHelpers"
    setup do
      @test_helpers = Deas::TestHelpers
    end
    subject{ @test_helpers }

  end

  class MixinTests < UnitTests
    desc "as a mixin"
    setup do
      context_class = Class.new{ include Deas::TestHelpers }
      @context = context_class.new
    end
    subject{ @context }

    should have_imeths :test_runner, :test_handler

  end

  class HandlerTestRunnerTests < MixinTests
    desc "for handler testing"
    setup do
      @handler_class = Class.new{ include Deas::ViewHandler }
      @runner  = @context.test_runner(@handler_class)
      @handler = @context.test_handler(@handler_class)
    end

    should "build a test runner for a given handler" do
      assert_kind_of ::Deas::TestRunner, @runner
      assert_kind_of Rack::Request,  @runner.request
      assert_kind_of Rack::Response, @runner.response
      assert_equal @runner.request.session, @runner.session
    end

    should "return an initialized handler instance" do
      assert_kind_of @handler_class, @handler
      assert_equal @runner.handler, @handler
    end

  end

end
