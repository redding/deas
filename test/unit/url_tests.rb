require 'assert'
require 'deas/url'

require 'test/support/empty_view_handler'

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
      @url = Deas::Url.new(:some_thing, '/:some/:thing/*')
      @url_with_escape = Deas::Url.new(:some_thing, '/:some/:thing/*', {
        :escape_query_value => proc{ |v| Rack::Utils.escape(v) }
      })
    end

    should "generate given named params only" do
      exp_path = '/a/goose/'
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose'
      })

      exp_path = '/a/goose/cooked'
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose',
        :splat => 'cooked'
      })

      exp_path = '/a/goose/cooked'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked'
      })
    end

    should "complain if given an empty named param value" do
      params = {
        'some' => 'a',
        :thing => 'goose'
      }
      empty_param_name  = params.keys.sample
      empty_param_value = [nil, ''].sample
      params[empty_param_name] = empty_param_value

      err = assert_raises EmptyNamedValueError do
        subject.path_for(params)
      end
      exp = "an empty value (`#{empty_param_value.inspect}`) "\
            "was given for the `#{empty_param_name}` url param"
      assert_equal exp, err.message
    end

    should "not complain if given empty splat param values" do
      exp_path = '/a/goose/'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => [nil, ''].sample
      })
    end

    should "append other (additional) params as query params" do
      exp_path = '/a/goose/cooked?aye=a&bee=b'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked',
        'bee'   => 'b',
        :aye    => 'a'
      })
    end

    should "escape query values when built with an escape query value proc" do
      exp_path = '/a/goose/cooked?aye=a?a&a'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked',
        :aye    => 'a?a&a'
      })

      exp_path = "/a/goose/cooked?aye=a%3Fa%26a"
      assert_equal exp_path, @url_with_escape.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked',
        :aye    => 'a?a&a'
      })
    end

    should "ignore any 'captures'" do
      exp_path = '/a/goose/cooked'
      assert_equal exp_path, subject.path_for({
        'some'     => 'a',
        :thing     => 'goose',
        'splat'    => 'cooked',
        'captures' => 'some-captures'
      })
    end

    should "append anchors" do
      exp_path = '/a/goose/cooked#an-anchor'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked',
        '#'     => 'an-anchor'
      })
    end

    should "ignore empty anchors" do
      exp_path = '/a/goose/cooked'
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => 'cooked',
        '#'     => [nil, ''].sample
      })
    end

    should "'squash' duplicate forward-slashes" do
      exp_path = '/a/goose/cooked'
      assert_equal exp_path, subject.path_for({
        'some'  => '/a',
        :thing  => '/goose',
        'splat' => '///cooked'
      })
    end

    should "not alter the given params" do
      params = {
        'some'    => 'thing',
        :splat    => 'splat',
        '#'       => 'anchor'
      }
      exp_params = params.dup

      subject.path_for(params)
      assert_equal exp_params, params
    end

    should "complain if given non-hash params" do
      assert_raises NonHashParamsError do
        subject.path_for([Factory.string, Factory.integer, nil].sample)
      end
    end

  end

end
