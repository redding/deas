require 'assert'
require 'deas/error_handler'

class Deas::ErrorHandler

  class BaseTests < Assert::Context
    desc "Deas::ErrorHandler"
    setup do
      @exception = RuntimeError.new
      @fake_app  = FakeApp.new
      @error_handler = Deas::ErrorHandler.new(@exception, @fake_app, [])
    end
    subject{ @error_handler }

    should have_instance_methods :run
    should have_class_methods :run

  end

  class RunTests < BaseTests
    desc "run"
    setup do
      @error_procs = [ proc do |exception|
        settings.exception_that_occurred = exception
        "my return value"
      end ]

      @error_handler = Deas::ErrorHandler.new(@exception, @fake_app, @error_procs)
      @response = @error_handler.run
    end

    should "run the proc in the context of the app" do
      assert_equal @exception, @fake_app.settings.exception_that_occurred
    end

    should "return whatever the proc returns" do
      assert_equal "my return value", @response
    end

  end

  class RunWithMultipleProcsTests < BaseTests
    desc "run with multiple procs"
    setup do
      @error_procs = [
        proc do |exception|
          settings.first_proc_run = true
          'first'
        end,
        proc do |exception|
          settings.second_proc_run = true
          'second'
        end,
        proc do |exception|
          settings.third_proc_run = true
          nil
        end
      ]

      @error_handler = Deas::ErrorHandler.new(@exception, @fake_app, @error_procs)
      @response = @error_handler.run
    end

    should "run all the error procs" do
      assert_equal true, @fake_app.settings.first_proc_run
      assert_equal true, @fake_app.settings.second_proc_run
      assert_equal true, @fake_app.settings.third_proc_run
    end

    should "return the last non-nil response" do
      assert_equal 'second', @response
    end

  end

  class RunWithProcsThatHaltTests < BaseTests
    desc "run with a proc that halts"
    setup do
      @error_procs = [
        proc do |exception|
          settings.first_proc_run = true
          halt 401
        end,
        proc do |exception|
          settings.second_proc_run = true
        end
      ]

      @error_handler = Deas::ErrorHandler.new(@exception, @fake_app, @error_procs)
      @response = catch(:halt){ @error_handler.run }
    end

    should "run error procs until one halts" do
      assert_equal true, @fake_app.settings.first_proc_run
      assert_nil @fake_app.settings.second_proc_run
    end

    should "return whatever was halted" do
      assert_equal [ 401 ], @response
    end

  end

end
