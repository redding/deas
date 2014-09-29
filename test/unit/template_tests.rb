require 'assert'
require 'test/support/fake_sinatra_call'
require 'deas/template'

class Deas::Template

  class UnitTests < Assert::Context
    desc "Deas::Template"
    setup do
      @fake_sinatra_call = FakeSinatraCall.new
      @template = Deas::Template.new(@fake_sinatra_call, 'users/index')
    end
    subject{ @template }

    should have_instance_methods :name, :options, :render, :engine

    should "symbolize it's name" do
      assert_equal :"users/index", subject.name
    end

    should "set it's scope option" do
      assert_instance_of Deas::Template::Scope, subject.options[:scope]
    end

    should "know a named template's render engine" do
      fake_sinatra_call = FakeSinatraCall.new(:views => TEST_SUPPORT_ROOT.join('views'))

      views_exist = Deas::Template.new(fake_sinatra_call, 'whatever')
      assert_equal 'erb',    views_exist.engine('layout1')
      assert_equal 'haml',   views_exist.engine('haml_layout1')
      assert_equal 'other',  views_exist.engine('some.html.file')
      assert_equal 'engine', views_exist.engine('some_file')
      assert_equal 'erb',    views_exist.engine('some_no_engine_extension')
      assert_equal 'erb',    views_exist.engine('does_not_exist')

      views_no_exist = Deas::Template.new(fake_sinatra_call, 'whatever', {
        :views => '/does/not/exist'
      })
      assert_equal 'erb', views_no_exist.engine('layout1')
      assert_equal 'erb', views_no_exist.engine('haml_layout1')
      assert_equal 'erb', views_no_exist.engine('some.html.file')
      assert_equal 'erb', views_no_exist.engine('some_file')
      assert_equal 'erb', views_no_exist.engine('some_no_engine_extension')
      assert_equal 'erb', views_no_exist.engine('does_not_exist')

    end

    should "call the sinatra_call's `erb` method with #render" do
      return_value = subject.render

      assert_equal subject.name,    return_value[0]
      assert_equal subject.options, return_value[1]
    end

  end

  class WithLayoutsTests < UnitTests
    desc "with layouts"
    setup do
      @template = Deas::Template.new(@fake_sinatra_call, 'users/index', {
        :layout => [ 'layouts/web', 'layouts/search' ]
      })
    end

    should "call the engine's `erb` method for each layout" do
      web_lay_render_args     = subject.render
      search_lay_render_args  = web_lay_render_args.block_call_result
      users_index_render_args = search_lay_render_args.block_call_result

      assert_equal :"layouts/web",    web_lay_render_args.template_name
      assert_equal :"layouts/search", search_lay_render_args.template_name
      assert_equal :"users/index",    users_index_render_args.template_name
    end

  end

  class ScopeTests < UnitTests
    desc "Deas::Template::RenderScope"
    setup do
      @scope = Deas::Template::Scope.new(@fake_sinatra_call)
    end
    subject{ @scope }

    should have_reader :sinatra_call
    should have_imeths :render, :partial, :escape_html, :h, :escape_url, :u

    should "call the sinatra_call's erb method with #render" do
      render_args = subject.render('my_template', {
        :views  => '/path/to/templates',
        :locals => { :something => true }
      }, &Proc.new{ '#render called this proc' })

      assert_equal :my_template, render_args.template_name
      assert_instance_of Deas::Template::Scope, render_args.opts[:scope]

      exp_locals = { :something => true }
      assert_equal exp_locals, render_args.opts[:locals]

      assert_equal '#render called this proc', render_args.block_call_result
    end

    should "call the sinatra_call's erb method with #partial" do
      render_args = subject.partial('part', {
        :something => true
      }, &Proc.new{ '#partial called this proc' })

      assert_equal :_part, render_args.template_name
      assert_instance_of Deas::Template::Scope, render_args.opts[:scope]

      exp_locals = { :something => true }
      assert_equal exp_locals, render_args.opts[:locals]

      assert_equal '#partial called this proc', render_args.block_call_result
    end

    should "escape html with #h or #escape_html" do
      exp_val = "&lt;strong&gt;&lt;&#x2F;strong&gt;"
      assert_equal exp_val, subject.escape_html("<strong></strong>")
      assert_equal exp_val, subject.h("<strong></strong>")
    end

    should "escape urls with #u or #escape_url" do
      exp_val = "%2Fpath%2Fto%2Fsomewhere"
      assert_equal exp_val, subject.escape_url("/path/to/somewhere")
      assert_equal exp_val, subject.u("/path/to/somewhere")
    end

  end

  class PartialTests < UnitTests
    desc "Partial"
    setup do
      @partial = Deas::Template::Partial.new(@fake_sinatra_call, 'users/index/listing', {
        :user => 'Joe Test'
      })
    end
    subject{ @partial }

    should "be a kind of Deas::Template" do
      assert_kind_of Deas::Template, subject
    end

    should "add an underscore to it's template's basename" do
      assert_equal :"users/index/_listing", subject.name
    end

    should "set it's locals option" do
      assert_equal({ :user => 'Joe Test' }, subject.options[:locals])
    end

  end

end
