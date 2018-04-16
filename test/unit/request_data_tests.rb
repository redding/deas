require 'assert'
require 'deas/request_data'

class Deas::RequestData

  class UnitTests < Assert::Context
    desc "Deas::RequestData"
    setup do
      @request    = Factory.string
      @response   = Factory.string
      @route_path = Factory.string
      @params     = Factory.string

      @request_data = Deas::RequestData.new({
        :request    => @request,
        :response   => @response,
        :route_path => @route_path,
        :params     => @params
      })
    end
    subject{ @request_data }

    should have_readers :request, :response, :route_path, :params

    should "know its attributes" do
      assert_equal @request,    subject.request
      assert_equal @response,   subject.response
      assert_equal @route_path, subject.route_path
      assert_equal @params,     subject.params
    end

    should "default its attributes when they aren't provided" do
      request_data = Deas::RequestData.new({})

      assert_nil request_data.request
      assert_nil request_data.response
      assert_nil request_data.route_path
      assert_nil request_data.params
    end

    should "know if it is equal to another request data" do
      request_data = Deas::RequestData.new({
        :request    => @request,
        :response   => @response,
        :route_path => @route_path,
        :params     => @params
      })
      assert_equal request_data, subject

      request_data = Deas::RequestData.new({})
      assert_not_equal request_data, subject
    end


  end

end
