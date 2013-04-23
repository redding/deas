require 'assert'
require 'deas/runner'
require 'test/support/view_handlers'

class Deas::Runner

  class BaseTests < Assert::Context
    desc "Deas::Runner"
    setup do
      @runner = Deas::Runner.new(TestViewHandler)
    end
    subject{ @runner }

    should have_instance_methods :request, :response, :params, :logger

    should "raise NotImplementedError with #halt" do
      assert_raises(NotImplementedError){ subject.halt }
    end

    should "raise NotImplementedError with #render" do
      assert_raises(NotImplementedError){ subject.render }
    end

  end

end
