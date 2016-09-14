require 'assert'
require 'deas/error_handler'

class Deas::ErrorHandler

  class UnitTests < Assert::Context
    desc "Deas::ErrorHandler"
    setup do
      # always make sure there are multiple error procs or tests can be false
      # positives
      @error_proc_spies = (Factory.integer(3) + 1).times.map{ ErrorProcSpy.new }
      @server_data      = Factory.server_data(:error_procs => @error_proc_spies)
      @request          = Factory.string
      @response         = Factory.string
      @handler_class    = Deas::ErrorHandler
      @handler          = Factory.string
      @params           = Factory.string
      @splat            = Factory.string
      @route_path       = Factory.string

      @context_hash = {
        :server_data   => @server_data,
        :request       => @request,
        :response      => @response,
        :handler_class => @handler_class,
        :handler       => @handler,
        :params        => @params,
        :splat         => @splat,
        :route_path    => @route_path
      }
    end
    subject{ @handler_class }

    should have_imeths :run

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @exception = Factory.exception
      @error_handler = @handler_class.new(@exception, @context_hash)
    end
    subject{ @error_handler }

    should have_readers :exception, :context, :error_procs
    should have_imeths :run

    should "know its attrs" do
      assert_equal @exception, subject.exception

      exp = Context.new(@context_hash)
      assert_equal exp, subject.context

      exp = @server_data.error_procs.reverse
      assert_equal exp, subject.error_procs
    end

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @response = @error_handler.run
    end

    should "call each of its procs" do
      subject.error_procs.each do |proc_spy|
        assert_true proc_spy.called
        assert_equal subject.exception, proc_spy.exception
        assert_equal subject.context,   proc_spy.context
      end
    end

    should "return the last non-nil response" do
      assert_nil @response

      exp = Factory.string
      subject.error_procs.first.response = exp
      assert_equal exp, subject.run
    end

  end

  class RunWithProcsThatRaiseTests < InitTests
    desc "and run with procs that raise exceptions"
    setup do
      @first_exception, @last_exception = Factory.exception, Factory.exception
      @error_handler.error_procs.first.raise_exception = @first_exception
      @error_handler.error_procs.last.raise_exception  = @last_exception

      @error_handler.run
    end

    should "call each of its procs" do
      subject.error_procs.each{ |proc_spy| assert_true proc_spy.called }
    end

    should "call each proc with the most recently raised exception" do
      assert_equal @exception,       @error_handler.error_procs.first.exception
      assert_equal @first_exception, @error_handler.error_procs.last.exception
    end

    should "alter the handler's exception to be the last raised exception" do
      assert_equal @last_exception, subject.exception
    end

  end

  class ContextTests < UnitTests
    desc "Context"
    setup do
      @context = Context.new(@context_hash)
    end
    subject{ @context }

    should have_readers :server_data
    should have_readers :request, :response, :handler_class, :handler
    should have_readers :params, :splat, :route_path

    should "know its attributes" do
      assert_equal @context_hash[:server_data],   subject.server_data
      assert_equal @context_hash[:request],       subject.request
      assert_equal @context_hash[:response],      subject.response
      assert_equal @context_hash[:handler_class], subject.handler_class
      assert_equal @context_hash[:handler],       subject.handler
      assert_equal @context_hash[:params],        subject.params
      assert_equal @context_hash[:splat],         subject.splat
      assert_equal @context_hash[:route_path],    subject.route_path
    end

    should "know if it equals another context" do
      exp = Context.new(@context_hash)
      assert_equal exp, subject

      exp = Context.new({
        :server_data   => Factory.server_data,
        :request       => Factory.string,
        :response      => Factory.string,
        :handler_class => Factory.string,
        :handler       => Factory.string,
        :params        => Factory.string,
        :splat         => Factory.string,
        :route_path    => Factory.string
      })
      assert_not_equal exp, subject
    end

  end

  class ErrorProcSpy
    attr_reader :called, :exception, :context
    attr_accessor :response, :raise_exception

    def initialize
      @called = false
    end

    def call(exception, context)
      @called    = true
      @exception = exception
      @context   = context

      raise self.raise_exception if self.raise_exception
      @response
    end
  end

end
