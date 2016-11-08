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
      server_data.before_route_run_procs.each do |c|
        c.call(server_data, request_data)
      end
      request_type_name = server_data.router.request_type_name(request_data.request)
      begin
        @handler_proxies[request_type_name].run(server_data, request_data)
      rescue HandlerProxyNotFound
        [404, Rack::Utils::HeaderHash.new, []]
      ensure
        server_data.after_route_run_procs.each do |c|
          c.call(server_data, request_data)
        end
      end
    end

  end

end
