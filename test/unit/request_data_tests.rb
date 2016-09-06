require 'assert'
require 'deas/request_data'

class Deas::RequestData

  class UnitTests < Assert::Context
    desc "Deas::RequestData"
    setup do
      @route_path = Factory.string
      @request    = Factory.string
      @response   = Factory.string
      @params     = Factory.string

      @server_data = Deas::RequestData.new({
        :route_path => @route_path,
        :request    => @request,
        :response   => @response,
        :params     => @params
      })
    end
    subject{ @server_data }

    should have_readers :route_path, :request, :response, :params

    should "know its attributes" do
      assert_equal @route_path, subject.route_path
      assert_equal @request,    subject.request
      assert_equal @response,   subject.response
      assert_equal @params,     subject.params
    end

    should "default its attributes when they aren't provided" do
      request_data = Deas::RequestData.new({})

      assert_nil request_data.route_path
      assert_nil request_data.request
      assert_nil request_data.response
      assert_nil request_data.params
    end

  end

end
