require 'assert'
require 'test/support/view_handlers'
require 'deas/route_proxy'
require 'deas/route'

class Deas::Route

  class UnitTests < Assert::Context
    desc "Deas::Route"
    setup do
      @handler_proxy = Deas::RouteProxy.new('EmptyViewHandler')
      @route = Deas::Route.new(:get, '/test', @handler_proxy)
    end
    subject{ @route }

    should have_readers :method, :path, :handler_proxy, :handler_class
    should have_imeths :validate!, :run

    should "know its method and path and handler_proxy" do
      assert_equal :get, subject.method
      assert_equal '/test', subject.path
      assert_equal @handler_proxy, subject.handler_proxy
    end

    should "set its handler class on `validate!`" do
      assert_nil subject.handler_class

      assert_nothing_raised{ subject.validate! }
      assert_equal EmptyViewHandler, subject.handler_class
    end

    should "complain given an invalid handler class" do
      proxy = Deas::RouteProxy.new('SomethingNotDefined')
      assert_raises(Deas::NoHandlerClassError) do
        Deas::Route.new(:get, '/test', proxy).validate!
      end
    end

  end

end
