module Deas

  class RequestData

    # The rack app uses this to "compile" the request-related data. The goal
    # here is to wrap up these (and any future) request objects into a struct
    # object to make them available to the runner/handler.  This is also to
    # decouple the rack app from the handlers (we can use any rack app as long
    # as they provide this data).

    attr_reader :route_path, :request, :response, :params

    def initialize(args)
      @route_path = args[:route_path]
      @request    = args[:request]
      @response   = args[:response]
      @params     = args[:params]
    end

  end

end
