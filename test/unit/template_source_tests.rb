require 'assert'
require 'deas/template_source'

require 'deas/logger'
require 'deas/template_engine'

class Deas::TemplateSource

  class UnitTests < Assert::Context
    desc "Deas::TemplateSource"
    subject{ Deas::TemplateSource }

    should "disallow certain engine extensions" do
      exp = [ 'rb' ]
      assert_equal exp, subject::DISALLOWED_ENGINE_EXTS
    end

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
      subject.engine 'test', @test_engine
      exp_opts = {
        'source_path'          => subject.path,
        'logger'               => @logger,
        'deas_template_source' => subject
      }
      assert_equal exp_opts, subject.engines['test'].opts

      subject.engine 'test', @test_engine, 'an' => 'opt'
      exp_opts = {
        'source_path'          => subject.path,
        'logger'               => @logger,
        'deas_template_source' => subject,
        'an'                   => 'opt'
      }
      assert_equal exp_opts, subject.engines['test'].opts

      subject.engine('test', @test_engine, {
        'source_path'          => 'something',
        'logger'               => 'another',
        'deas_template_source' => 'tempsource'
      })
      exp_opts = {
        'source_path'          => 'something',
        'logger'               => 'another',
        'deas_template_source' => 'tempsource'
      }
      assert_equal exp_opts, subject.engines['test'].opts

      source = Deas::TemplateSource.new(@source_path)
      source.engine('test', @test_engine)
      assert_instance_of Deas::NullLogger, source.engines['test'].opts['logger']
    end

    should "complain if registering a disallowed temp" do
      assert_kind_of Deas::NullTemplateEngine, subject.engines['rb']
      assert_raises DisallowedEngineExtError do
        subject.engine 'rb', @test_engine
      end
      assert_kind_of Deas::NullTemplateEngine, subject.engines['rb']
    end

    should "know if it has an engine registered for a given template name" do
      assert_false subject.engine_for?('test_template')

      subject.engine 'test', @test_engine
      assert_true subject.engine_for?('test_template')
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

    should "only try rendering template files its has engines for" do
      # there should be 2 files called "template" in `test/support` with diff
      # extensions
      exp = 'render-json-engine'
      assert_equal exp, subject.render('template', @v, @l)
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError) do
        subject.render(Factory.string, @v, @l)
      end
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
      exp = "partial-test-engine\n"
      assert_equal exp, subject.partial('test_template', @l)
    end

    should "only try rendering template files its has engines for" do
      # there should be 2 files called "template" in `test/support` with diff
      # extensions
      exp = 'partial-json-engine'
      assert_equal exp, subject.partial('template', @l)
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError) do
        subject.partial(Factory.string, @l)
      end
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
      "render-test-engine on #{template_name}\n" +
      (content || proc{}).call.to_s
    end
    def partial(template_name, locals, &content)
      "partial-test-engine\n" + (content || proc{}).call.to_s
    end
    def capture_partial(template_name, locals, &content)
      'capture-partial-test-engine'
    end
  end

  class JsonEngine < Deas::TemplateEngine
    def render(template_name, view_handler, locals, &content)
      'render-json-engine'
    end
    def partial(template_name, locals)
      'partial-json-engine'
    end
    def capture_partial(template_name, locals, &content)
      'capture-partial-json-engine'
    end
  end

  TestViewHandler = Class.new do
    def self.layouts; []; end
  end

  LayoutViewHandler = Class.new do
    def self.layouts; ['test_layout1', 'test_layout2']; end
  end

end
