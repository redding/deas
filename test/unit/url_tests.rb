require 'assert'
require 'deas/url'

require 'test/support/view_handlers'

class Deas::Url

  class BaseTests < Assert::Context
    desc "Deas::Url"
    setup do
      @url = Deas::Url.new(:get_info, '/info')
    end
    subject{ @url }

    should have_readers :name, :path

    should "know its name and path info" do
      assert_equal :get_info, subject.name
      assert_equal '/info', subject.path
    end

  end

end
