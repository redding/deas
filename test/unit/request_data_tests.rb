require 'assert'
require 'deas/request_data'

class Deas::RequestData

  class UnitTests < Assert::Context
    desc "Deas::RequestData"
    setup do
      @request    = Factory.string
      @response   = Factory.string
      @params     = Factory.string
      @route_path = Factory.string

      @server_data = Deas::RequestData.new({
        :request    => @request,
        :response   => @response,
        :params     => @params,
        :route_path => @route_path
      })
    end
    subject{ @server_data }

    should have_readers :request, :response, :params, :route_path

    should "know its attributes" do
      assert_equal @request,    subject.request
      assert_equal @response,   subject.response
      assert_equal @params,     subject.params
      assert_equal @route_path, subject.route_path
    end

    should "default its attributes when they aren't provided" do
      request_data = Deas::RequestData.new({})

      assert_nil request_data.request
      assert_nil request_data.response
      assert_nil request_data.params
      assert_nil request_data.route_path
    end

  end

end
