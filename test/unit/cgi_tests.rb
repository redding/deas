require 'assert'
require 'deas/cgi'

module Deas::Cgi

  class UnitTests < Assert::Context
    desc "Deas::Cgi"
    subject{ Deas::Cgi }

    should have_imeths :escape, :http_query

    should "cgi-escape data values" do
      exp = "Right%21%20%5BSaid%5D%20Fred.%0D%0A"
      assert_equal exp, Deas::Cgi.escape("Right! [Said] Fred.\r\n")
    end

    should "create http query strings" do
      exp = "name=thomas%20hardy%20%2F%20thomas%20handy"
      assert_equal exp, Deas::Cgi.http_query(:name => 'thomas hardy / thomas handy')

      exp = "id=23423&since=2009-10-14"
      assert_equal exp, Deas::Cgi.http_query(:id => 23423, :since => "2009-10-14")

      exp = "id[]=1&id[]=2"
      assert_equal exp, Deas::Cgi.http_query(:id => [1,2])

      exp = "poo[bar]=2&poo[foo]=1"
      assert_equal exp, Deas::Cgi.http_query(:poo => {:foo => 1, :bar => 2})

      exp = "poo[bar][bar1]=1&poo[bar][bar2]=nasty&poo[foo]=1"
      assert_equal exp, Deas::Cgi.http_query(:poo => {:foo => 1, :bar => {:bar1 => 1, :bar2 => "nasty"}})
    end

  end

end
