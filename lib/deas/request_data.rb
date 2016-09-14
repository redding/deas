module Deas

  class RequestData

    # The rack app uses this to "compile" the request-related data. The goal
    # here is to wrap up these (and any future) request objects into a struct
    # object to make them available to the runner/handler.  This is also to
    # decouple the rack app from the handlers (we can use any rack app as long
    # as they provide this data).

    attr_reader :request, :response, :params, :route_path

    def initialize(args)
      @request    = args[:request]
      @response   = args[:response]
      @params     = args[:params]
      @route_path = args[:route_path]
    end

    def ==(other_request_data)
      if other_request_data.kind_of?(RequestData)
        self.request    == other_request_data.request    &&
        self.response   == other_request_data.response   &&
        self.params     == other_request_data.params     &&
        self.route_path == other_request_data.route_path
      else
        super
      end
    end

  end

end
