require 'assert'
require 'deas/template'
require 'test/support/fake_app'

class Deas::Template

  class BaseTests < Assert::Context
    desc "Deas::Template"
    setup do
      @fake_sinatra_call = FakeApp.new
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
      fake_app = FakeApp.new(:views => TEST_SUPPORT_ROOT.join('views'))

      views_exist = Deas::Template.new(fake_app, 'whatever')
      assert_equal 'erb',    views_exist.engine('layout1')
      assert_equal 'haml',   views_exist.engine('haml_layout1')
      assert_equal 'other',  views_exist.engine('some.html.file')
      assert_equal 'engine', views_exist.engine('some_file')
      assert_equal 'erb',    views_exist.engine('some_no_engine_extension')
      assert_equal 'erb',    views_exist.engine('does_not_exist')

      views_no_exist = Deas::Template.new(fake_app, 'whatever', {
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

  class WithLayoutsTests < BaseTests
    desc "with layouts"
    setup do
      @template = Deas::Template.new(@fake_sinatra_call, 'users/index', {
        :layout => [ 'layouts/web', 'layouts/search' ]
      })
    end

    should "call the engine's `erb` method for each layout, " \
           "in the `layout` option" do
      return_value = subject.render

      # the return_value is a one-dimensional array of all the render args
      # used in order. Thus the, 0, 2, 4 nature of the indexes.
      assert_equal :"layouts/web",    return_value[0]
      assert_equal :"layouts/search", return_value[2]
      assert_equal :"users/index",    return_value[4]
    end

  end

  class ScopeTests < BaseTests
    desc "Deas::Template::RenderScope"
    setup do
      @scope = Deas::Template::Scope.new(@fake_sinatra_call)
    end
    subject{ @scope }

    should have_imeths :partial, :escape_html, :h, :escape_url, :u, :render

    should "call the sinatra_call's erb method with #partial" do
      return_value = subject.partial('part', :something => true)

      assert_equal :_part, return_value[0]

      expected_options = return_value[1]
      assert_instance_of Deas::Template::Scope, expected_options[:scope]

      expected_locals = { :something => true }
      assert_equal(expected_locals, expected_options[:locals])
    end

    should "call the sinatra_call's erb method with #render" do
      return_value = subject.render('my_template', {
        :views  => '/path/to/templates',
        :locals => { :something => true }
      })

      assert_equal :my_template, return_value[0]

      expected_options = return_value[1]
      assert_instance_of Deas::Template::Scope, expected_options[:scope]

      expected_locals = { :something => true }
      assert_equal(expected_locals, expected_options[:locals])
    end

    should "escape html with #h or #escape_html" do
      return_value = subject.escape_html("<strong></strong>")
      assert_equal "&lt;strong&gt;&lt;&#x2F;strong&gt;", return_value

      return_value = subject.h("<strong></strong>")
      assert_equal "&lt;strong&gt;&lt;&#x2F;strong&gt;", return_value
    end

    should "escape urls with #u or #escape_url" do
      return_value = subject.escape_url("/path/to/somewhere")
      assert_equal "%2Fpath%2Fto%2Fsomewhere", return_value

      return_value = subject.u("/path/to/somewhere")
      assert_equal "%2Fpath%2Fto%2Fsomewhere", return_value
    end

  end

  class PartialTests < BaseTests
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
