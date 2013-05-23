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

    should have_reader  :app_settings
    should have_readers :request, :response, :params, :logger, :session
    should have_imeths :halt, :redirect, :content_type, :status, :render

    should "raise NotImplementedError with #halt" do
      assert_raises(NotImplementedError){ subject.halt }
    end

    should "raise NotImplementedError with #redirect" do
      assert_raises(NotImplementedError){ subject.redirect }
    end

    should "raise NotImplementedError with #content_type" do
      assert_raises(NotImplementedError){ subject.content_type }
    end

    should "raise NotImplementedError with #status" do
      assert_raises(NotImplementedError){ subject.status }
    end

    should "raise NotImplementedError with #render" do
      assert_raises(NotImplementedError){ subject.render }
    end

  end

end
