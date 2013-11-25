require 'assert'
require 'deas/test_runner'

require 'test/support/view_handlers'

class Deas::TestRunner

  class UnitTests < Assert::Context
    desc "Deas::TestRunner"
    setup do
      @runner = Deas::TestRunner.new(TestRunnerViewHandler)
    end
    subject{ @runner }

    should have_readers :handler, :return_value

    should "build a handler instance" do
      assert_kind_of TestRunnerViewHandler, subject.handler
    end

    should "default the handler settings" do
      assert_kind_of OpenStruct, subject.app_settings
      assert_kind_of Deas::NullLogger, subject.logger
      assert_equal Hash.new, subject.params
      assert_nil subject.request
      assert_nil subject.response
      assert_nil subject.session
    end

    should "write any non-standard settings on the handler" do
      runner = Deas::TestRunner.new(TestRunnerViewHandler, :custom_value => 42)
      assert_equal 42, runner.handler.custom_value
    end

    should "not set a return value on initialize" do
      assert_nil subject.return_value
    end

    should "set its return value to the return value of `run!` on run" do
      assert_nil subject.return_value
      subject.run
      assert_equal subject.handler.run!, subject.return_value
    end

    should "build halt args if halt is called" do
      value = catch(:halt){ subject.halt }
      assert_kind_of HaltArgs, value
      [:body, :headers, :status].each do |meth|
        assert_respond_to meth, value
      end
    end

    should "build redirect args if redirect is called" do
      value = subject.redirect '/some/path'
      assert_kind_of RedirectArgs, value
      [:path, :halt_args].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal '/some/path', value.path
      assert value.redirect?
    end

    should "build content type args if content type is called" do
      value = subject.content_type 'something'
      assert_kind_of ContentTypeArgs, value
      [:value, :opts].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal 'something', value.value
    end

    should "build status args if status is called" do
      value = subject.status(432)
      assert_kind_of StatusArgs, value
      assert_respond_to :value, value
      assert_equal 432, value.value
    end

    should "build headers args if headers is called" do
      value = subject.headers(:some => 'thing')
      assert_kind_of HeadersArgs, value
      assert_respond_to :value, value
      exp_val = {:some => 'thing'}
      assert_equal exp_val, value.value
    end

    should "build render args if render is called" do
      value = subject.render 'some/template'
      assert_kind_of RenderArgs, value
      [:template_name, :options, :block].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal 'some/template', value.template_name
    end

    should "build send file args if send file is called" do
      value = subject.send_file 'some/file/path'
      assert_kind_of SendFileArgs, value
      [:file_path, :options, :block].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal 'some/file/path', value.file_path
    end

  end

end
