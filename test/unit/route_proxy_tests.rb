require 'assert'
require 'deas/route_proxy'

require 'deas/test_helpers'
require 'test/support/view_handlers'

class Deas::RouteProxy

  class UnitTests < Assert::Context
    desc "Deas::RouteProxy"
    setup do
      @proxy = Deas::RouteProxy.new('EmptyViewHandler')
    end
    subject{ @proxy }

    should have_readers :handler_class_name, :handler_class
    should have_imeths :validate!

    should "know its handler class name" do
      assert_equal 'EmptyViewHandler', subject.handler_class_name
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
