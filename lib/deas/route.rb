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

    def run(server_data, sinatra_call)
      type = server_data.router.request_type_name(sinatra_call.request)
      proxy = begin
        @handler_proxies[type]
      rescue HandlerProxyNotFound
        sinatra_call.halt(404)
      end
      # TODO: eventually stop sending sinatra call (part of phasing out Sinatra)
      proxy.run(server_data, sinatra_call)
    end

  end

end
