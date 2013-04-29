require 'assert'

class Deas::RunnerLogger

  class BaseTests < Assert::Context
    desc "Deas::RunnerLogger"
    setup do
      @logger = Logger.new(File.open("/dev/null", 'w'))
      @runner_logger = Deas::RunnerLogger.new(@logger)
    end
    subject{ @runner_logger }

    should have_instance_methods :verbose, :summary

    should "use the passed logger as #verbose and a null logger as #summary " \
           "when passed true as the second arg" do
      runner_logger = Deas::RunnerLogger.new(@logger, true)

      assert_equal @logger, runner_logger.verbose
      assert_instance_of Deas::NullLogger, runner_logger.summary
    end

    should "use the passed logger as #summary and a null logger as #verbose " \
           "when passed false as the second arg" do
      runner_logger = Deas::RunnerLogger.new(@logger, false)

      assert_instance_of Deas::NullLogger, runner_logger.verbose
      assert_equal @logger, runner_logger.summary
    end

  end

end
