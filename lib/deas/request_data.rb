module Deas

  class RequestData

    # The rack app uses this to "compile" the request-related data. The goal
    # here is to wrap up these (and any future) request objects into a struct
    # object to make them available to the runner/handler.  This is also to
    # decouple the rack app from the handlers (we can use any rack app as long
    # as they provide this data).

    attr_reader :request, :response, :route_path, :params

    def initialize(args)
      @request    = args[:request]
      @response   = args[:response]
      @route_path = args[:route_path]
      @params     = args[:params]
    end

    def ==(other_request_data)
      if other_request_data.kind_of?(RequestData)
        self.request    == other_request_data.request    &&
        self.response   == other_request_data.response   &&
        self.route_path == other_request_data.route_path &&
        self.params     == other_request_data.params
      else
        super
      end
    end

  end

end
