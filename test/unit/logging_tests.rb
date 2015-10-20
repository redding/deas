require 'assert'
require 'deas/logging'

module Deas::Logging

  class UnitTests < Assert::Context
    desc "Deas::Logging"
    subject{ Deas::Logging }

    should have_imeths :middleware

    should "return a middleware class given a verbose flag" do
      assert_equal Deas::VerboseLogging, subject.middleware(true)
      assert_equal Deas::SummaryLogging, subject.middleware(false)
    end

  end

  class CallSetupTests < UnitTests
    setup do
      @logger = SpyLogger.new
      @app = Factory.sinatra_call({
        :deas_server_data => Factory.server_data(:logger => @logger)
      })

      @app_call_env = nil
      @resp_status  = Factory.integer
      @resp_headers = { 'Location' => Factory.path }
      @app_response = [@resp_status, @resp_headers, [Factory.text]]
      Assert.stub(@app, :call) do |env|
        # dup so we can see what keys were added before supering
        @app_call_env = env.dup
        @app_response
      end

      @env = {
        'REQUEST_METHOD' => Factory.string(3).upcase,
        'PATH_INFO'      => Factory.path,
        'rack.run_once'  => true
      }
    end
    subject{ @middleware_class }

  end

  class BaseLoggingTests < CallSetupTests
    desc "Deas::BaseLogging"
    setup do
      @middleware_class = Deas::BaseLogging
    end

  end

  class BaseLoggingInitTests < BaseLoggingTests
    desc "when init"
    setup do
      @benchmark = Benchmark.measure{}
      Assert.stub(Benchmark, :measure) do |&block|
        block.call
        @benchmark
      end

      @middleware = @middleware_class.new(@app)
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "call the app and return its response when called" do
      response = subject.call(@env)
      assert_not_nil @app_call_env
      assert_equal @app_response, response
    end

    should "set the rack.logger env key before its app is called" do
      subject.call(@env)
      assert_equal @logger, @env['rack.logger']
      assert_same @env['rack.logger'], @app_call_env['rack.logger']
    end

    should "benchmark calling its app and set the deas.time_taken env key" do
      assert_nil @env['deas.time_taken']
      subject.call(@env)
      exp = Deas::RoundedTime.new(@benchmark.real)
      assert_equal exp, @env['deas.time_taken']
    end

    should "log a deas.error env key if it exists" do
      @env.delete('deas.error')
      subject.call(@env)
      assert_empty @logger.info_logged

      @env['deas.error'] = error = Factory.exception
      subject.call(@env)
      exp = "[Deas] #{error.class}: #{error.message}\n" \
            "#{(error.backtrace || []).join("\n")}"
      assert_includes exp, @logger.info_logged
    end

  end

  class VerboseLoggingTests < CallSetupTests
    desc "Deas::VerboseLogging"
    setup do
      @middleware_class = Deas::VerboseLogging
    end

    should "be a base logging middleware" do
      assert subject < Deas::BaseLogging
    end

    should "know its response status names" do
      exp = {
        200 => 'OK',
        302 => 'FOUND',
        400 => 'BAD REQUEST',
        401 => 'UNAUTHORIZED',
        403 => 'FORBIDDEN',
        404 => 'NOT FOUND',
        408 => 'TIMEOUT',
        500 => 'ERROR'
      }
      assert_equal exp, @middleware_class::RESPONSE_STATUS_NAMES
    end

  end

  class VerboseLoggingInitTests < VerboseLoggingTests
    desc "when init"
    setup do
      @resp_status = @middleware_class::RESPONSE_STATUS_NAMES.keys.choice
      @app_response[0] = @resp_status

      @middleware = Deas::VerboseLogging.new(@app)
    end
    subject{ @middleware }

    should have_imeths :call!

    should "call the app and return its response when called" do
      response = subject.call(@env)
      assert_not_nil @app_call_env
      assert_equal @app_response, response
    end

    should "set the deas.logging env key before calling its app" do
      assert_nil @env['deas.logging']
      subject.call(@env)
      assert_instance_of Proc, @env['deas.logging']

      message = Factory.text
      @env['deas.logging'].call(message)
      assert_includes "[Deas] #{message}", @logger.info_logged

      assert_same @env['deas.logging'], @app_call_env['deas.logging']
    end

    should "log the request when called" do
      assert_empty @logger.info_logged
      subject.call(@env)
      status = "#{@resp_status}, " \
               "#{@middleware_class::RESPONSE_STATUS_NAMES[@resp_status]}"
      exp = [
        "[Deas] ===== Received request =====",
        "[Deas]   Method:  #{@env['REQUEST_METHOD'].inspect}",
        "[Deas]   Path:    #{@env['PATH_INFO'].inspect}",
        "[Deas]   Redir:   #{@resp_headers['Location']}",
        "[Deas] ===== Completed in #{@env['deas.time_taken']}ms (#{status}) ====="
      ]
      assert_equal exp, @logger.info_logged
    end

    should "not log a redir line if it doesn't have a Location header" do
      @resp_headers.delete('Location')
      subject.call(@env)

      exp = "[Deas]   Redir:   #{@resp_headers['Location']}"
      assert_not_includes exp, @logger.info_logged
    end

    should "not log a status name for unknown statuses" do
      @resp_status = Factory.integer
      @app_response[0] = @resp_status
      subject.call(@env)

      exp = "[Deas] ===== Completed in #{@env['deas.time_taken']}ms (#{@resp_status}) ====="
      assert_includes exp, @logger.info_logged
    end

  end

  class SummaryLoggingTests < CallSetupTests
    desc "Deas::SummaryLogging"
    setup do
      @middleware_class = Deas::SummaryLogging
    end

    should "be a base logging middleware" do
      assert subject < Deas::BaseLogging
    end

  end

  class SummaryLoggingInitTests < SummaryLoggingTests
    desc "when init"
    setup do
      @params = { Factory.string => Factory.string }
      @handler_class = TestHandler
      @env.merge!({
        'deas.params'        => @params,
        'deas.handler_class' => @handler_class
      })

      @middleware = Deas::SummaryLogging.new(@app)
    end
    subject{ @middleware }

    should "call the app and return its response when called" do
      response = subject.call(@env)
      assert_not_nil @app_call_env
      assert_equal @app_response, response
    end

    should "set the deas.logging env key before calling its app" do
      assert_nil @env['deas.logging']
      subject.call(@env)
      assert_instance_of Proc, @env['deas.logging']
      assert_nil @env['deas.logging'].call(Factory.text)
      assert_same @env['deas.logging'], @app_call_env['deas.logging']
    end

    should "log the request when called" do
      assert_empty @logger.info_logged
      subject.call(@env)

      summary_line = Deas::SummaryLine.new({
        'method'  => @env['REQUEST_METHOD'],
        'path'    => @env['PATH_INFO'],
        'params'  => @env['deas.params'],
        'time'    => @env['deas.time_taken'],
        'status'  => @resp_status,
        'handler' => @handler_class.name,
        'redir'   => @resp_headers['Location']
      })
      assert_includes "[Deas] #{summary_line}", @logger.info_logged
    end

    should "not log a handler when it doesn't have a handler class" do
      @env.delete('deas.handler_class')
      subject.call(@env)

      summary_line = Deas::SummaryLine.new({
        'method'  => @env['REQUEST_METHOD'],
        'path'    => @env['PATH_INFO'],
        'params'  => @env['deas.params'],
        'time'    => @env['deas.time_taken'],
        'status'  => @resp_status,
        'redir'   => @resp_headers['Location']
      })
      assert_includes "[Deas] #{summary_line}", @logger.info_logged
    end

    should "not log a redir if it doesn't have a Location header" do
      @resp_headers.delete('Location')
      subject.call(@env)

      summary_line = Deas::SummaryLine.new({
        'method'  => @env['REQUEST_METHOD'],
        'path'    => @env['PATH_INFO'],
        'params'  => @env['deas.params'],
        'time'    => @env['deas.time_taken'],
        'status'  => @resp_status,
        'handler' => @handler_class.name,
      })
      assert_includes "[Deas] #{summary_line}", @logger.info_logged
    end

  end

  class SummaryLineTests < UnitTests
    desc "Deas::SummaryLine"
    subject{ Deas::SummaryLine }

    should "output its attributes in a specific order" do
      assert_equal %w{time status method path handler params redir}, subject.keys
    end

    should "output its attributes in a single line" do
      line_attrs = {
        'time'    => 't',
        'status'  => 's',
        'method'  => 'm',
        'path'    => 'pth',
        'handler' => 'h',
        'params'  => 'p',
        'redir'   => 'r'
      }
      exp_line = "time=\"t\" "\
                 "status=\"s\" "\
                 "method=\"m\" "\
                 "path=\"pth\" "\
                 "handler=\"h\" "\
                 "params=\"p\" "\
                 "redir=\"r\""
      assert_equal exp_line, subject.new(line_attrs)
    end

    should "only output keys if data exists for them" do
      line_attrs = {
        'status'  => 's',
        'path'    => 'pth',
        'handler' => 'h',
        'params'  => 'p'
      }
      exp_line = "status=\"s\" "\
                 "path=\"pth\" "\
                 "handler=\"h\" "\
                 "params=\"p\""
      assert_equal exp_line, subject.new(line_attrs)
    end

  end

  TestHandler = Class.new

  class SpyLogger
    attr_reader :info_logged

    def initialize
      @info_logged = []
    end

    def info(message);  @info_logged  << message; end
  end

end
