require 'assert'
require 'deas/json_view_handler'

require 'deas/test_helpers'

module Deas::JsonViewHandler

  class UnitTests < Assert::Context
    desc "Deas::JsonViewHandler"
    setup do
      @handler_class = TestJsonHandler
    end
    subject{ @handler_class }

    should "be a Deas ViewHandler" do
      assert_includes Deas::ViewHandler, subject
    end

  end

  class InitTests < UnitTests
    include Deas::TestHelpers

    desc "when init"
    setup do
      @runner  = test_runner(@handler_class)
      @handler = @runner.handler
    end
    subject{ @runner }

    should "force its content type to :json" do
      assert_equal :json, subject.content_type.value
    end

    should "default its body and headers if not provided" do
      @handler.status = Factory.integer
      response = @runner.run

      assert_equal @handler.status, response.status
      assert_equal({},              response.headers)
      assert_equal '{}',            response.body
    end

    should "allow halting with a body and headers" do
      @handler.status  = Factory.integer
      @handler.headers = { Factory.string => Factory.string }
      @handler.body    = Factory.text
      response = @runner.run

      assert_equal @handler.status,  response.status
      assert_equal @handler.headers, response.headers
      assert_equal @handler.body,    response.body
    end

  end

  class TestJsonHandler
    include Deas::JsonViewHandler

    attr_accessor :status, :headers, :body

    def run!
      args = [status, headers, body].compact
      halt *args
    end

  end

end
