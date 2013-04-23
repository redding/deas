require 'assert'
require 'deas/route'
require 'test/support/fake_app'
require 'test/support/view_handlers'

class Deas::Route

  class BaseTests < Assert::Context
    desc "Deas::Route"
    setup do
      @route = Deas::Route.new(:get, '/test', 'TestViewHandler')
    end
    subject{ @route }

    should have_instance_methods :method, :path, :handler_class_name,
      :handler_class, :run

    should "constantize the handler class with #constantize!" do
      assert_nil subject.handler_class

      assert_nothing_raised{ subject.constantize! }

      assert_equal TestViewHandler, subject.handler_class
    end

    should "raise a custom exception if the handler class name " \
           "can't be constantized" do
      route = Deas::Route.new(:get, '/', 'SomethingNotDefined')

      assert_raises(Deas::NoHandlerClassError) do
        route.constantize!
      end
    end

  end

  class RunTests < BaseTests
    desc "run"
    setup do
      @route.constantize!

      @fake_app = FakeApp.new
      Deas::Runner.stubs(:run).with(TestViewHandler, @fake_app).returns('test')
    end
    teardown do
      Deas::Runner.unstub(:run)
    end

    should "run the view handler and set a status code, headers and body" do
      return_value = subject.run(@fake_app)

      assert_equal 'test', return_value
    end

  end

end
