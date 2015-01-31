require 'assert'
require 'deas/test_runner'

require 'rack/test'
require 'deas/runner'
require 'deas/template_source'
require 'test/support/normalized_params_spy'
require 'test/support/view_handlers'

class Deas::TestRunner

  class UnitTests < Assert::Context
    desc "Deas::TestRunner"
    setup do
      @handler_class = TestRunnerViewHandler
      @runner_class = Deas::TestRunner
    end
    subject{ @runner_class }

    should "be a `Runner`" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @params = { 'value' => '1' }
      @args = {
        :request  => 'a-request',
        :response => 'a-response',
        :session  => 'a-session',
        :params   => @params,
        :logger   => 'a-logger',
        :router   => 'a-router',
        :template_source => 'a-source'
      }

      @norm_params_spy = Deas::Runner::NormalizedParamsSpy.new
      Assert.stub(NormalizedParams, :new){ |p| @norm_params_spy.new(p) }

      @runner = @runner_class.new(@handler_class, @args)
    end
    subject{ @runner }

    should have_readers :return_value
    should have_imeths :run

    should "raise an invalid error when not passed a view handler" do
      assert_raises(Deas::InvalidServiceHandlerError) do
        @runner_class.new(Class.new)
      end
    end

    should "super its standard args" do
      assert_equal 'a-request',  subject.request
      assert_equal 'a-response', subject.response
      assert_equal 'a-session',  subject.session
      assert_equal @params,      subject.params
      assert_equal 'a-logger',   subject.logger
      assert_equal 'a-router',   subject.router
      assert_equal 'a-source',   subject.template_source
    end

    should "call to normalize its params" do
      assert_equal @params, @norm_params_spy.params
      assert_true @norm_params_spy.value_called
    end

    should "write any non-standard args on the handler" do
      runner = @runner_class.new(@handler_class, :custom_value => 42)
      assert_equal 42, runner.handler.custom_value
    end

    should "not have called its service handlers before callbacks" do
      assert_not_true subject.handler.before_called
    end

    should "have called init on its service handler" do
      assert_true subject.handler.init_called
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
      value = catch(:halt){ subject.redirect '/some/path' }
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
      template_name = Factory.path
      locals = { Factory.string => Factory.string }
      args = subject.render template_name, locals

      assert_kind_of RenderArgs, args
      [:template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal template_name, args.template_name
      assert_equal locals,        args.locals
    end

    should "build source render args if source source render is called" do
      source = Deas::TemplateSource.new(Factory.path)
      template_name = Factory.path
      locals = { Factory.string => Factory.string }
      args = subject.source_render source, template_name, locals

      assert_kind_of SourceRenderArgs, args
      [:source, :template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal source,        args.source
      assert_equal template_name, args.template_name
      assert_equal locals,        args.locals
    end

    should "build partial args if partial is called" do
      template_name = Factory.path
      locals = { Factory.string => Factory.string }
      args = subject.partial template_name, locals

      assert_kind_of PartialArgs, args
      [:template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal template_name, args.template_name
      assert_equal locals,        args.locals
    end

    should "build source partial args if source partial is called" do
      source = Deas::TemplateSource.new(Factory.path)
      template_name = Factory.path
      locals = { Factory.string => Factory.string }
      args = subject.source_partial source, template_name, locals

      assert_kind_of SourcePartialArgs, args
      [:source, :template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal source,        args.source
      assert_equal template_name, args.template_name
      assert_equal locals,        args.locals
    end

    should "build send file args if send file is called" do
      path = Factory.path
      args = subject.send_file path

      assert_kind_of SendFileArgs, args
      [:file_path, :options, :block].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal path, args.file_path
    end

  end

  class NormalizedParamsTests < UnitTests
    desc "NormalizedParams"
    setup do
      @norm_params_class = Deas::TestRunner::NormalizedParams
    end

    should "be a normalized params subclass" do
      assert @norm_params_class < Deas::Runner::NormalizedParams
    end

    should "not convert Tempfile param values to strings" do
      tempfile = Class.new(::Tempfile){ def initialize; end }.new
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of ::Tempfile, params['attachment']['tempfile']
    end

    should "not convert File param values to strings" do
      tempfile = File.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of ::File, params['attachment']['tempfile']
    end

    should "not convert Rack::Multipart::UploadedFile param values to strings" do
      tempfile = Rack::Multipart::UploadedFile.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of Rack::Multipart::UploadedFile, params['attachment']['tempfile']
    end

    should "not convert Rack::Test::UploadedFile param values to strings" do
      tempfile = Rack::Test::UploadedFile.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of Rack::Test::UploadedFile, params['attachment']['tempfile']
    end

    private

    def normalized(params)
      @norm_params_class.new(params).value
    end

  end

end
