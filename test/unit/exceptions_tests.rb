require 'assert'
require 'deas/exceptions'

module Deas

  class ErrorTests < Assert::Context
    desc "Deas"

    should "provide an error exception that subclasses `RuntimeError" do
      assert Deas::Error
      assert_kind_of RuntimeError, Deas::Error.new
    end

    should "provide a no handler class exception" do
      assert Deas::NoHandlerClassError

      handler_class_name = 'AHandlerClass'
      e = Deas::NoHandlerClassError.new(handler_class_name)
      exp_msg = "Deas couldn't find the view handler '#{handler_class_name}'" \
                " - it doesn't exist or hasn't been required in yet."

      assert_kind_of Deas::Error, e
      assert_equal exp_msg, e.message
    end

    should "provide a server exception" do
      assert Deas::ServerError
      assert_kind_of Deas::Error, Deas::ServerError.new
    end

    should "provide a server root exception" do
      assert Deas::ServerRootError

      e = Deas::ServerRootError.new
      assert_kind_of Deas::ServerError, e
      assert_equal "server `root` not set but required", e.message
    end

    should "provide a handler proxy not found exception" do
      assert Deas::HandlerProxyNotFound
      assert_kind_of Deas::Error, Deas::HandlerProxyNotFound.new
    end

    should "provide a generic not found exception" do
      assert Deas::NotFound
      assert_kind_of Deas::Error, Deas::NotFound.new
    end

  end

end
