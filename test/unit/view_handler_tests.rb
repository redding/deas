require 'assert'
require 'deas/view_handler'

require 'deas/template_source'
require 'rack/request'
require 'rack/response'
require 'test/support/view_handlers'

module Deas::ViewHandler

  class UnitTests < Assert::Context
    include Deas::ViewHandler::TestHelpers

    desc "Deas::ViewHandler"
    setup do
      @handler_class = TestViewHandler
    end
    subject{ @handler_class }

    should have_imeths :layout, :layouts
    should have_imeths :before, :prepend_before, :before_callbacks
    should have_imeths :after,  :prepend_after,  :after_callbacks
    should have_imeths :before_init, :prepend_before_init, :before_init_callbacks
    should have_imeths :after_init,  :prepend_after_init,  :after_init_callbacks
    should have_imeths :before_run,  :prepend_before_run,  :before_run_callbacks
    should have_imeths :after_run,   :prepend_after_run,   :after_run_callbacks

    should "specify layouts" do
      subject.layout 'layouts/app'
      assert_equal ['layouts/app'], subject.layouts.map(&:call)

      subject.layout { 'layouts/web' }
      assert_equal ['layouts/app', 'layouts/web'], subject.layouts.map(&:call)
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @runner  = test_runner(@handler_class)
      @handler = @runner.handler
    end
    subject{ @handler }

    should have_imeths :init, :init!, :run, :run!
    should have_imeths :layouts

    should "have called `init!` and it's callbacks" do
      assert_equal true, subject.before_init_called
      assert_equal true, subject.second_before_init_called
      assert_equal true, subject.init_bang_called
      assert_equal true, subject.after_init_called
    end

    should "not have called `run!` or it's callbacks when initialized" do
      assert_nil subject.before_run_called
      assert_nil subject.run_bang_called
      assert_nil subject.after_run_called
    end

    should "know if it is equal to another view handler" do
      handler = test_handler(@handler_class)
      assert_equal handler, subject

      handler = test_handler(Class.new{ include Deas::ViewHandler })
      assert_not_equal handler, subject
    end

  end

  class LayoutsTests < InitTests
    desc "with layouts"
    setup do
      @params = { 'n' => Factory.integer }
      @runner  = test_runner(LayoutsViewHandler, :params => @params)
      @handler = @runner.handler
    end

    should "build its layouts by instance eval'ing its class layout procs" do
      exp = subject.class.layouts.map{ |proc| @handler.instance_eval(&proc) }
      assert_equal exp, subject.layouts
    end

  end

  class RunTests < InitTests
    desc "and run"

    should "call `run!` and it's callbacks" do
      subject.run
      assert_equal true, subject.before_run_called
      assert_equal true, subject.run_bang_called
      assert_equal true, subject.after_run_called
    end

    should "complain if run! is not overwritten" do
      assert_raises(NotImplementedError){ test_runner(EmptyViewHandler).run }
    end

    should "send files" do
      send_file_args = test_runner(SendFileViewHandler).run
      assert_equal "my_file.txt",      send_file_args.file_path
      assert_equal({:some => :option}, send_file_args.options)
    end

  end

  class RenderTests < RunTests
    setup do
      @template_name = Factory.path
      @locals = { Factory.string => Factory.string }
      @source = Deas::TemplateSource.new(Factory.path)

      @render_args = nil
      Assert.stub(@runner.template_source, :render){ |*args| @render_args = args }
      @source_render_args = nil
      Assert.stub(@source, :render){ |*args| @source_render_args = args }
      @partial_args = nil
      Assert.stub(@runner.template_source, :partial){ |*args| @partial_args = args }
      @source_partial_args = nil
      Assert.stub(@source, :partial){ |*args| @source_partial_args = args }
    end

    should "render templates" do
      subject.send(:render, @template_name, @locals)
      exp = [@template_name, subject, @locals]
      assert_equal exp, @render_args

      subject.send(:source_render, @source, @template_name, @locals)
      exp = [@template_name, subject, @locals]
      assert_equal exp, @source_render_args

      subject.send(:partial, @template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @partial_args

      subject.send(:source_partial, @source, @template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @source_partial_args
    end

  end

  class CallbackTests < UnitTests
    setup do
      @proc1 = proc{ '1' }
      @proc2 = proc{ '2' }
      @handler = Class.new{ include Deas::ViewHandler }
    end

    should "append procs in #before_callbacks with #before" do
      @handler.before(&@proc1); @handler.before(&@proc2)
      assert_equal @proc1, @handler.before_callbacks.first
      assert_equal @proc2, @handler.before_callbacks.last
    end

    should "prepend procs in #before_callbacks with #before" do
      @handler.prepend_before(&@proc1); @handler.prepend_before(&@proc2)
      assert_equal @proc2, @handler.before_callbacks.first
      assert_equal @proc1, @handler.before_callbacks.last
    end

    should "append procs in #after_callbacks with #after" do
      @handler.after(&@proc1); @handler.after(&@proc2)
      assert_equal @proc1, @handler.after_callbacks.first
      assert_equal @proc2, @handler.after_callbacks.last
    end

    should "prepend procs in #after_callbacks with #before" do
      @handler.prepend_after(&@proc1); @handler.prepend_after(&@proc2)
      assert_equal @proc2, @handler.after_callbacks.first
      assert_equal @proc1, @handler.after_callbacks.last
    end

    should "append procs in #before_init_callbacks with #before_init" do
      @handler.before_init(&@proc1); @handler.before_init(&@proc2)
      assert_equal @proc1, @handler.before_init_callbacks.first
      assert_equal @proc2, @handler.before_init_callbacks.last
    end

    should "prepend procs in #before_init_callbacks with #before" do
      @handler.prepend_before_init(&@proc1); @handler.prepend_before_init(&@proc2)
      assert_equal @proc2, @handler.before_init_callbacks.first
      assert_equal @proc1, @handler.before_init_callbacks.last
    end

    should "append procs in #after_init_callbacks with #after_init" do
      @handler.after_init(&@proc1); @handler.after_init(&@proc2)
      assert_equal @proc1, @handler.after_init_callbacks.first
      assert_equal @proc2, @handler.after_init_callbacks.last
    end

    should "prepend procs in #after_init_callbacks with #before" do
      @handler.prepend_after_init(&@proc1); @handler.prepend_after_init(&@proc2)
      assert_equal @proc2, @handler.after_init_callbacks.first
      assert_equal @proc1, @handler.after_init_callbacks.last
    end

    should "append procs in #before_run_callbacks with #before_run" do
      @handler.before_run(&@proc1); @handler.before_run(&@proc2)
      assert_equal @proc1, @handler.before_run_callbacks.first
      assert_equal @proc2, @handler.before_run_callbacks.last
    end

    should "prepend procs in #before_run_callbacks with #before" do
      @handler.prepend_before_run(&@proc1); @handler.prepend_before_run(&@proc2)
      assert_equal @proc2, @handler.before_run_callbacks.first
      assert_equal @proc1, @handler.before_run_callbacks.last
    end

    should "append procs in #after_run_callbacks with #after_run" do
      @handler.after_run(&@proc1); @handler.after_run(&@proc2)
      assert_equal @proc1, @handler.after_run_callbacks.first
      assert_equal @proc2, @handler.after_run_callbacks.last
    end

    should "prepend procs in #after_run_callbacks with #before" do
      @handler.prepend_after_run(&@proc1); @handler.prepend_after_run(&@proc2)
      assert_equal @proc2, @handler.after_run_callbacks.first
      assert_equal @proc1, @handler.after_run_callbacks.last
    end

  end

  class HaltTests < UnitTests
    desc "halt"

    should "return a response with the status code and the passed data" do
      runner = test_runner(HaltViewHandler, :params => {
        'code'    => 200,
        'headers' => { 'Content-Type' => 'text/plain' },
        'body'    => 'test halting'
      })
      runner.run

      assert_equal 200,                                runner.response_value.status
      assert_equal({ 'Content-Type' => 'text/plain' }, runner.response_value.headers)
      assert_equal 'test halting',                     runner.response_value.body
    end

  end

  class ContentTypeTests < UnitTests
    desc "content_type"

    should "should set the response content_type/charset" do
      runner = test_runner(ContentTypeViewHandler)
      content_type_args = runner.run

      assert_equal 'text/plain', content_type_args.value
      assert_equal({:charset => 'latin1'}, content_type_args.opts)
    end

  end

  class StatusTests < UnitTests
    desc "status"

    should "should set the response status" do
      runner = test_runner(StatusViewHandler)
      status_args = runner.run

      assert_equal 422, status_args.value
    end

  end

  class HeadersTests < UnitTests
    desc "headers"

    should "should set the response status" do
      runner = test_runner(HeadersViewHandler)
      headers_args = runner.run
      exp_headers = {
        'a-header' => 'some value',
        'other'    => 'other'
      }

      assert_equal exp_headers, headers_args.value
    end

  end

  class TestHelpersTests < UnitTests
    desc "TestHelpers"
    setup do
      context_class = Class.new{ include Deas::ViewHandler::TestHelpers }
      @context = context_class.new
    end
    subject{ @context }

    should have_imeths :test_runner, :test_handler

    should "build a test runner for a given handler class" do
      runner  = subject.test_runner(@handler_class)

      assert_kind_of ::Deas::TestRunner, runner
      assert_kind_of Rack::Request,  runner.request
      assert_equal runner.request.session, runner.session
    end

    should "return an initialized handler instance" do
      handler = subject.test_handler(@handler_class)
      assert_kind_of @handler_class, handler

      exp = subject.test_runner(@handler_class).handler
      assert_equal exp, handler
    end

  end

  class TestViewHandler
    include Deas::ViewHandler

    attr_reader :before_called, :after_called
    attr_reader :before_init_called, :second_before_init_called
    attr_reader :init_bang_called, :after_init_called
    attr_reader :before_run_called, :run_bang_called, :after_run_called

    before{ @before_called = true }
    after{  @after_called  = true }

    before_init{ @before_init_called        = true }
    before_init{ @second_before_init_called = true }
    after_init{  @after_init_called         = true }
    before_run{  @before_run_called         = true }
    after_run{   @after_run_called          = true }

    def init!; @init_bang_called = true; end
    def run!;  @run_bang_called = true;  end

  end

  class LayoutsViewHandler
    include Deas::ViewHandler

    layout '1.html'
    layout { '2.html' }
    layout { "#{params['n']}.html" }

  end

end
