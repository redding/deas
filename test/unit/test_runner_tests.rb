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
      @runner_class  = Deas::TestRunner
    end
    subject{ @runner_class }

    should "be a `Runner`" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @request = Factory.request
      @params  = { Factory.string => Factory.string }

      @args = {
        :logger          => Factory.string,
        :router          => Factory.string,
        :template_source => Factory.string,
        :request         => @request,
        :session         => Factory.string,
        :params          => @params
      }

      @norm_params_spy = Deas::Runner::NormalizedParamsSpy.new
      Assert.stub(NormalizedParams, :new){ |p| @norm_params_spy.new(p) }

      @runner = @runner_class.new(@handler_class, @args)
    end
    subject{ @runner }

    should have_imeths :halted?, :run

    should "raise an invalid error when not passed a view handler" do
      assert_raises(Deas::InvalidServiceHandlerError) do
        @runner_class.new(Class.new)
      end
    end

    should "super its standard args" do
      assert_equal @args[:logger],          subject.logger
      assert_equal @args[:router],          subject.router
      assert_equal @args[:template_source], subject.template_source
      assert_equal @args[:request],         subject.request
      assert_equal @args[:session],         subject.session
      assert_equal @args[:params],          subject.params
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

    should "have called init (but not run) on its handler" do
      assert_true     subject.handler.init_called
      assert_not_true subject.handler.run_called
    end

    should "not have set a run return value" do
      assert_nil subject.run
    end

    should "not be halted by default" do
      assert_false subject.halted?
    end

    should "not call `run` on the handler if halted when run" do
      catch(:halt){ subject.halt }
      assert_true subject.halted?
      subject.run
      assert_not_true subject.handler.run_called
    end

    should "return its run return value when run" do
      catch(:halt){ subject.halt }
      return_val = subject.run
      assert_kind_of HaltArgs, return_val
    end

  end

  class HaltWithArgsTests < InitTests
    setup do
      @status    = Factory.integer
      @headers   = { Factory.string => Factory.string }
      @body      = [Factory.text]
      @halt_args = [@status, @headers, @body]
    end

  end

  class HaltTests < HaltWithArgsTests
    desc "the `halt` method"
    setup do
      catch(:halt){ @runner.halt(*@halt_args) }
    end

    should "put the runner in the halted state" do
      assert_true subject.halted?
    end

    should "set halt args as the run return value" do
      return_val = subject.run

      assert_kind_of HaltArgs, return_val
      assert_equal @status,  return_val.status
      assert_equal @headers, return_val.headers
      assert_equal @body,    return_val.body
    end

    should "super to the base runner" do
      assert_equal @status,  subject.status
      assert_equal @headers, subject.headers
      assert_equal @body,    subject.body
    end

  end

  class RedirectTests < HaltWithArgsTests
    desc "the `redirect` method"
    setup do
      @location = Factory.string
      catch(:halt){ @runner.redirect(@location, *@halt_args) }
    end

    should "put the runner in the halted state" do
      assert_true subject.halted?
    end

    should "set redirect args as the run return value" do
      return_val = subject.run

      assert_kind_of RedirectArgs, return_val
      assert_equal @location, return_val.location

      assert_kind_of HaltArgs, return_val.halt_args
      assert_equal @status,  return_val.halt_args.status
      assert_equal @headers, return_val.halt_args.headers
      assert_equal @body,    return_val.halt_args.body
    end

    should "super to the base runner" do
      assert_equal @status, subject.status

      exp = { 'Location' => get_absolute_url(@location) }.merge(@headers)
      assert_equal exp, subject.headers

      assert_equal @body, subject.body
    end

    private

    def get_absolute_url(url)
      File.join("#{@request.env['rack.url_scheme']}://#{@request.env['HTTP_HOST']}", url)
    end

  end

  class SendFileTests < InitTests
    desc "the `send_file` method"
    setup do
      # set an existing file path so the base method will look to the opts
      @file_path = TEST_SUPPORT_ROOT.join("file1.txt")
      # set an opt that the base method will actually do something with
      @opts = { :filename => Factory.string }

      catch(:halt){ @runner.send_file(@file_path, @opts) }
    end

    should "put the runner in the halted state" do
      assert_true subject.halted?
    end

    should "set send file args as the run return value" do
      return_val = subject.run

      assert_kind_of SendFileArgs, return_val
      assert_equal @file_path, return_val.file_path
      assert_equal @opts,      return_val.opts
    end

    should "super to the base runner" do
      assert_equal 200, subject.status

      exp = "attachment;filename=\"#{@opts[:filename]}\""
      assert_equal exp, subject.headers['Content-Disposition']

      assert_instance_of Deas::Runner::SendFileBody, subject.body
    end

  end

  class RenderSetupTests < InitTests
    setup do
      @template_name = Factory.path
      @locals = { Factory.string => Factory.string }
      @source = Deas::TemplateSource.new(Factory.path)
    end

  end

  class SourceRenderTests < RenderSetupTests
    desc "the `source_render` method"
    setup do
      @source_render_called_with = nil
      Assert.stub(@source, :render){ |*args| @source_render_called_with = args }

      @runner.source_render(@source, @template_name, @locals)
    end

    should "set render args as the run return value" do
      return_val = subject.run

      assert_kind_of RenderArgs, return_val
      assert_equal @source,        return_val.source
      assert_equal @template_name, return_val.template_name
      assert_equal @locals,        return_val.locals
    end

    should "super to the base runner" do
      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @source_render_called_with
    end

  end

  class SourcePartialTests < RenderSetupTests
    desc "the `source_partial` method"
    setup do
      @source_partial_called_with = nil
      Assert.stub(@source, :partial){ |*args| @source_partial_called_with = args }

      @return_val = @runner.source_partial(@source, @template_name, @locals)
    end

    should "super to the base runner" do
      exp = [@template_name, @locals]
      assert_equal exp, @source_partial_called_with
    end

    should "return render args" do
      assert_kind_of RenderArgs, @return_val
      assert_equal @source,        @return_val.source
      assert_equal @template_name, @return_val.template_name
      assert_equal @locals,        @return_val.locals
    end

    should "not affect the run return val" do
      assert_nil subject.run
    end

  end

  class HaltArgsTests < UnitTests
    desc "HaltArgs"
    setup do
      @status    = Factory.integer
      @headers   = { Factory.string => Factory.string }
      @body      = [Factory.text]
      @halt_args = [@status, @headers, @body]
      @orig_args = @halt_args.dup

      @args = HaltArgs.new(@halt_args)
    end
    subject{ @args }

    should have_imeths :status, :headers, :body

    should "know its attrs" do
      args = HaltArgs.new([])
      assert_nil args.status
      assert_nil args.headers
      assert_nil args.body

      args = HaltArgs.new([@status])
      assert_equal @status, args.status
      assert_nil args.headers
      assert_nil args.body

      args = HaltArgs.new([@headers])
      assert_nil args.status
      assert_equal @headers, args.headers
      assert_nil args.body

      args = HaltArgs.new([@body])
      assert_nil args.status
      assert_nil args.headers
      assert_equal @body, args.body

      args = HaltArgs.new([@status, @headers])
      assert_equal @status,  args.status
      assert_equal @headers, args.headers
      assert_nil args.body

      args = HaltArgs.new([@status, @body])
      assert_equal @status, args.status
      assert_nil args.headers
      assert_equal @body, args.body

      args = HaltArgs.new([@headers, @body])
      assert_nil args.status
      assert_equal @headers, args.headers
      assert_equal @body,    args.body

      args = HaltArgs.new([@status, @headers, @body])
      assert_equal @status,  args.status
      assert_equal @headers, args.headers
      assert_equal @body,    args.body
    end

    should "not alter the given args" do
      assert_equal @orig_args, @halt_args
    end

  end

  class RedirectArgsTests < UnitTests
    desc "RedirectArgs"
    setup do
      @location  = Factory.string
      @halt_args = HaltArgs.new([])

      @args = RedirectArgs.new(@location, @halt_args)
    end
    subject{ @args }

    should have_imeths :location, :halt_args
    should have_imeths :redirect?

    should "know its attrs" do
      assert_equal @location,  subject.location
      assert_equal @halt_args, subject.halt_args
      assert_true subject.redirect?
    end

  end

  class SendFileArgsTests < UnitTests
    desc "SendFileArgs"
    setup do
      @file_path = Factory.path
      @opts      = { Factory.string => Factory.string }

      @args = SendFileArgs.new(@file_path, @opts)
    end
    subject{ @args }

    should have_imeths :file_path, :opts

    should "know its attrs" do
      assert_equal @file_path, subject.file_path
      assert_equal @opts,      subject.opts
    end

  end

  class RenderArgsTests < UnitTests
    desc "RenderArgs"
    setup do
      @source        = Factory.string
      @template_name = Factory.path
      @locals        = { Factory.string => Factory.string }

      @args = RenderArgs.new(@source, @template_name, @locals)
    end
    subject{ @args }

    should have_imeths :source, :template_name, :locals

    should "know its attrs" do
      assert_equal @source,        subject.source
      assert_equal @template_name, subject.template_name
      assert_equal @locals,        subject.locals
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
