require 'assert'
require 'deas/route_proxy'

require 'deas/exceptions'
require 'deas/handler_proxy'
require 'test/support/view_handlers'

class Deas::RouteProxy

  class UnitTests < Assert::Context
    desc "Deas::RouteProxy"
    setup do
      @proxy = Deas::RouteProxy.new('EmptyViewHandler')
    end
    subject{ @proxy }

    should "be a HandlerProxy" do
      assert_kind_of Deas::HandlerProxy, subject
    end

    should "complain if given a nil handler class name" do
      assert_raises(Deas::NoHandlerClassError) do
        Deas::RouteProxy.new(nil)
      end
    end

    should "apply no view handler ns if none given" do
      assert_equal 'EmptyViewHandler', subject.handler_class_name
    end

    should "apply an optional view handler ns if it is given" do
      proxy = Deas::RouteProxy.new('NsTest', 'MyStuff')
      assert_equal 'MyStuff::NsTest', proxy.handler_class_name
    end

    should "ignore the ns when given a class name with leading colons" do
      proxy = Deas::RouteProxy.new('::NoNsTest', 'MyStuff')
      assert_equal '::NoNsTest', proxy.handler_class_name
    end

    should "set its handler class on `validate!`" do
      assert_nil subject.handler_class

      assert_nothing_raised{ subject.validate! }
      assert_equal EmptyViewHandler, subject.handler_class
    end

    should "complain if there is no handler class with the given name" do
      assert_raises(Deas::NoHandlerClassError) do
        Deas::RouteProxy.new('SomethingNotDefined').validate!
      end
    end

  end

end
