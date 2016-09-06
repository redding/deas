require 'deas/exceptions'

module Deas

  class Route

    attr_reader :method, :path, :handler_proxies

    def initialize(method, path, handler_proxies)
      @method, @path, @handler_proxies = method, path, handler_proxies
    end

    def validate!
      @handler_proxies.each do |request_type_name, proxy|
        proxy.validate!
      end
    end

    def run(server_data, request_data)
      request_type_name = server_data.router.request_type_name(request_data.request)
      begin
        @handler_proxies[request_type_name].run(server_data, request_data)
      rescue HandlerProxyNotFound
        [404, Rack::Utils::HeaderHash.new, []]
      end
    end

  end

end
