require 'assert'
require 'deas/url'

require 'test/support/view_handlers'

class Deas::Url

  class UnitTests < Assert::Context
    desc "Deas::Url"
    setup do
      @url_class = Deas::Url
    end
    subject{ @url_class }

    should have_imeths :http_query

    should "create http query strings" do
      params = {
        Factory.string        => Factory.string,
        Factory.integer       => Factory.integer(3).times.map{ Factory.string },
        Factory.string.to_sym => { Factory.string => Factory.string }
      }
      exp = params.map{ |(k, v)| "#{k}=#{v}" }.sort.join('&')
      assert_equal exp, @url_class.http_query(params)

      exp = params.map{ |(k, v)| "#{k}=#{v.inspect}" }.sort.join('&')
      assert_equal exp, @url_class.http_query(params){ |v| v.inspect }
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @url = Deas::Url.new(:get_info, '/info')
    end
    subject{ @url }

    should have_readers :name, :path, :escape_query_value_proc
    should have_imeth :path_for

    should "know its name and path info" do
      assert_equal :get_info, subject.name
      assert_equal '/info', subject.path
    end

    should "know its escape query value proc" do
      assert_nil subject.escape_query_value_proc

      escape_proc = proc{ Factory.string }
      url = Deas::Url.new(Factory.string, Factory.path, {
        :escape_query_value => escape_proc
      })
      assert escape_proc, subject.escape_query_value_proc
    end

  end

  class PathForTests < InitTests
    desc "when generating paths"
    setup do
      @url = Deas::Url.new(:some_thing, '/:some/:thing/*/*')
      @url_with_escape = Deas::Url.new(:some_thing, '/:some/:thing/*/*', {
        :escape_query_value => proc{ |v| Rack::Utils.escape(v) }
      })
    end

    should "generate given named params only" do
      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose'
      })

      exp_path = "/a/goose/cooked-well/*"
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose',
        :splat => ['cooked-well']
      })

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well']
      })
    end

    should "append other (additional) params as query params" do
      exp_path = "/a/goose/cooked/well?aye=a&bee=b"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        'bee'   => 'b',
        :aye    => 'a'
      })
    end

    should "escape query values when built with an escape query value proc" do
      exp_path = "/a/goose/cooked/well?aye=a?a&a"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        :aye    => 'a?a&a'
      })

      exp_path = "/a/goose/cooked/well?aye=a%3Fa%26a"
      assert_equal exp_path, @url_with_escape.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        :aye    => 'a?a&a'
      })
    end

    should "ignore any 'captures'" do
      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        'captures' => 'some-captures'
      })
    end

    should "append anchors" do
      exp_path = "/a/goose/cooked/well#an-anchor"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        '#'     => 'an-anchor'
      })
    end

    should "ignore empty anchors" do
      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        '#'     => nil
      })

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        '#'     => ''
      })
    end

    should "generate given ordered params only" do
      exp_path = "/a/:thing/*/*"
      assert_equal exp_path, subject.path_for('a')

      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for('a', 'goose')

      exp_path = "/a/goose/cooked-well/*"
      assert_equal exp_path, subject.path_for('a', 'goose', 'cooked-well')

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for('a', 'goose', 'cooked', 'well')
    end

    should "generate given mixed ordered and named params" do
      exp_path = "/:some/:thing/*/*"
      assert_equal exp_path, subject.path_for

      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for('a', 'thing' => 'goose')

      exp_path = "/goose/a/well/*"
      assert_equal exp_path, subject.path_for('a', 'well', 'some' => 'goose')

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for('ignore', 'these', 'params', {
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well']
      })
    end

    should "'squash' duplicate forward-slashes" do
      exp_path = "/a/goose/cooked/well/"
      assert_equal exp_path, subject.path_for({
        'some'  => '/a',
        :thing  => '/goose',
        'splat' => ['///cooked', 'well//']
      })
    end

    should "not alter the given params" do
      params = {
        'some'    => 'thing',
        :captures => 'captures',
        :splat    => 'splat',
        '#'       => 'anchor'
      }
      exp_params = params.dup

      subject.path_for(params)
      assert_equal exp_params, params
    end

  end

end
