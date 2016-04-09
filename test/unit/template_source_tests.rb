require 'assert'
require 'deas/template_source'

require 'deas/logger'
require 'deas/template_engine'

class Deas::TemplateSource

  class UnitTests < Assert::Context
    desc "Deas::TemplateSource"
    subject{ Deas::TemplateSource }

  end

  class InitTests < Assert::Context
    setup do
      @source_path = ROOT.join('test/support').to_s
      @logger = 'a-logger'
      @source = Deas::TemplateSource.new(@source_path, @logger)
    end
    subject{ @source }

    should have_readers :path, :engines
    should have_imeths :engine, :engine_for?
    should have_imeths :render, :partial

    should "know its path" do
      assert_equal @source_path.to_s, subject.path
    end

  end

  class EngineRegistrationTests < InitTests
    desc "when registering an engine"
    setup do
      @test_engine = TestEngine
    end

    should "allow registering new engines" do
      assert_kind_of Deas::NullTemplateEngine, subject.engines['test']
      subject.engine 'test', @test_engine
      assert_kind_of @test_engine, subject.engines['test']
    end

    should "register with default options" do
      engine_ext = Factory.string
      subject.engine engine_ext, @test_engine
      exp_opts = {
        'source_path'             => subject.path,
        'logger'                  => @logger,
        'default_template_source' => subject,
        'ext'                     => engine_ext
      }
      assert_equal exp_opts, subject.engines[engine_ext].opts

      custom_opts = { Factory.string => Factory.string }
      subject.engine engine_ext, @test_engine, custom_opts
      exp_opts = {
        'source_path'             => subject.path,
        'logger'                  => @logger,
        'default_template_source' => subject,
        'ext'                     => engine_ext
      }.merge(custom_opts)
      assert_equal exp_opts, subject.engines[engine_ext].opts

      custom_opts = {
        'source_path'             => 'something',
        'logger'                  => 'another',
        'default_template_source' => 'tempsource',
        'ext'                     => Factory.string
      }
      subject.engine(engine_ext, @test_engine, custom_opts)
      exp_opts = custom_opts.merge('ext' => engine_ext)
      assert_equal exp_opts, subject.engines[engine_ext].opts

      source = Deas::TemplateSource.new(@source_path)
      source.engine(engine_ext, @test_engine)
      assert_instance_of Deas::NullLogger, source.engines[engine_ext].opts['logger']
    end

  end

  class RenderOrPartialTests < InitTests
    setup do
      @source.engine('test', TestEngine)
      @source.engine('json', JsonEngine)

      @v = TestViewHandler.new
      @l = {}
      @c = Proc.new{}
    end

  end

  class RenderTests < RenderOrPartialTests
    desc "when rendering a template"

    should "call `render` on the configured engine" do
      exp = "render-test-engine on test_template\n"
      assert_equal exp, subject.render('test_template', @v, @l)
    end

    should "compile multiple engine outputs if template has multi-engine exts" do
      exp = "render-json-engine on template-compiled1\ncompile-test-engine"
      assert_equal exp, subject.render('template-compiled1', @v, @l)

      exp = "render-test-engine on template-compiled2\ncompile-json-engine"
      assert_equal exp, subject.render('template-compiled2', @v, @l)

      exp = "render-json-engine on template-compiled3\n"
      assert_equal exp, subject.render('template-compiled3', @v, @l)

      exp = "This is a json template for use in template source/engine tests.\n"\
            "compile-json-engine"
      assert_equal exp, subject.render('template-compiled4', @v, @l)
    end

    should "complain if the given template name matches multiple templates" do
      # there should be more than 1 file called "template" in `test/support`
      # with various extensions
      assert_raises(ArgumentError){ subject.render('template', @v, @l) }
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError){ subject.render(Factory.string, @v, @l) }
    end

  end

  class RenderLayoutsTests < RenderOrPartialTests
    desc "when rendering a template in layouts"
    setup do
      @v = LayoutViewHandler.new
    end

    should "render view handlers with layouts" do
      exp = "render-test-engine on test_layout1\n"\
            "render-test-engine on test_layout2\n"\
            "render-test-engine on test_template\n"
      assert_equal exp, subject.render('test_template', @v, @l)
    end

  end

  class PartialTests < RenderTests
    desc "when partial rendering a template"

    should "call `partial` on the configured engine" do
      exp = "partial-test-engine on test_template\n"
      assert_equal exp, subject.partial('test_template', @l)
    end

    should "compile multiple engine outputs if template has multi-engine exts" do
      exp = "partial-json-engine on template-compiled1\ncompile-test-engine"
      assert_equal exp, subject.partial('template-compiled1', @l)

      exp = "partial-test-engine on template-compiled2\ncompile-json-engine"
      assert_equal exp, subject.partial('template-compiled2', @l)
    end

    should "complain if the given template name matches multiple templates" do
      # there should be more than 1 file called "template" in `test/support`
      # with various extensions
      assert_raises(ArgumentError){ subject.partial('template', @l) }
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError){ subject.partial(Factory.string, @l) }
    end

  end

  class NullTemplateSourceTests < Assert::Context
    desc "Deas::NullTemplateSource"
    setup do
      @source = Deas::NullTemplateSource.new
    end
    subject{ @source }

    should "be a template source" do
      assert_kind_of Deas::TemplateSource, subject
    end

    should "have an empty path string" do
      assert_equal '', subject.path
    end

  end

  class TestEngine < Deas::TemplateEngine
    def render(template_name, view_handler, locals, &content)
      "render-test-engine on #{template_name}\n" + (content || proc{}).call.to_s
    end
    def partial(template_name, locals, &content)
      "partial-test-engine on #{template_name}\n" + (content || proc{}).call.to_s
    end
    def compile(template_name, content)
      "#{content}compile-test-engine"
    end
  end

  class JsonEngine < Deas::TemplateEngine
    def render(template_name, view_handler, locals, &content)
      "render-json-engine on #{template_name}\n" + (content || proc{}).call.to_s
    end
    def partial(template_name, locals, &content)
      "partial-json-engine on #{template_name}\n" + (content || proc{}).call.to_s
    end
    def compile(template_name, content)
      "#{content}compile-json-engine"
    end
  end

  TestViewHandler = Class.new do
    def layouts; []; end
  end

  LayoutViewHandler = Class.new do
    def layouts; ['test_layout1', 'test_layout2']; end
  end

end
