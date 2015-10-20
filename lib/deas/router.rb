require 'rack'
require 'deas/exceptions'
require 'deas/url'

module Deas

  class Router

    DEFAULT_REQUEST_TYPE_NAME = 'default'

    attr_reader :request_types, :urls, :routes
    attr_reader :escape_query_value_proc

    def initialize(&block)
      @request_types = []
      @urls, @routes = {}, []
      default_request_type_name(DEFAULT_REQUEST_TYPE_NAME)
      escape_query_value{ |v| Rack::Utils.escape(v) }
      self.instance_eval(&block) if !block.nil?
    end

    def view_handler_ns(value = nil)
      @view_handler_ns = value if !value.nil?
      @view_handler_ns
    end

    def escape_query_value(&block)
      raise(ArgumentError, "no block given") unless block
      @escape_query_value_proc = block
    end

    def base_url(value = nil)
      set_base_url(value) if !value.nil?
      @base_url
    end

    def set_base_url(value)
      @base_url = value
    end

    def prepend_base_url(url_path)
      "#{base_url}#{url_path}"
    end

    def url(name, path, options = nil)
      if !path.kind_of?(::String)
        raise ArgumentError, "invalid path `#{path.inspect}` - "\
                             "can only provide a url name with String paths"
      end
      add_url(name.to_sym, path, options || {})
    end

    def url_for(name, *args)
      url = self.urls[name.to_sym]
      raise ArgumentError, "no route named `#{name.to_sym.inspect}`" unless url
      prepend_base_url(url.path_for(*args))
    end

    def default_request_type_name(value = nil)
      @default_request_type = RequestType.new(value) if !value.nil?
      @default_request_type.name
    end

    def add_request_type(name, &proc)
      @request_types << RequestType.new(name, proc)
    end

    # ideally someday the request should just *know* its request type
    def request_type_name(request)
      (self.request_types.detect{ |rt| rt.proc.call(request) } || @default_request_type).name
    end

    def get(path, *args);    self.route(:get,    path, *args); end
    def post(path, *args);   self.route(:post,   path, *args); end
    def put(path, *args);    self.route(:put,    path, *args); end
    def patch(path, *args);  self.route(:patch,  path, *args); end
    def delete(path, *args); self.route(:delete, path, *args); end

    def route(http_method, from_path, *args)
      handler_names        = args.last.kind_of?(::Hash) ? args.pop : {}
      default_handler_name = args.last
      if !handler_names.key?(self.default_request_type_name) && default_handler_name
        handler_names[self.default_request_type_name] = default_handler_name
      end

      from_url = self.urls[from_path]
      if from_path.kind_of?(::Symbol) && from_url.nil?
        raise ArgumentError, "no url named `#{from_path.inspect}`"
      end
      from_url_path = from_url.path if from_url

      require 'deas/route_proxy'
      proxies = handler_names.inject({}) do |proxies, (req_type_name, handler_name)|
        proxies[req_type_name] = Deas::RouteProxy.new(handler_name, self.view_handler_ns)
        proxies
      end

      add_route(http_method, prepend_base_url(from_url_path || from_path), proxies)
    end

    def redirect(from_path, to_path = nil, &block)
      to_url = self.urls[to_path]
      if to_path.kind_of?(::Symbol) && to_url.nil?
        raise ArgumentError, "no url named `#{to_path.inspect}`"
      end
      from_url = self.urls[from_path]
      if from_path.kind_of?(::Symbol) && from_url.nil?
        raise ArgumentError, "no url named `#{from_path.inspect}`"
      end
      from_url_path = from_url.path if from_url

      require 'deas/redirect_proxy'
      proxy = Deas::RedirectProxy.new(self, to_url || to_path, &block)
      proxies = { self.default_request_type_name => proxy }

      add_route(:get, prepend_base_url(from_url_path || from_path), proxies)
    end

    private

    def add_url(name, path, options)
      options[:escape_query_value] ||= self.escape_query_value_proc
      self.urls[name] = Deas::Url.new(name, path, {
        :escape_query_value => options[:escape_query_value]
      })
    end

    def add_route(http_method, path, proxies)
      proxies = HandlerProxies.new(proxies, self.default_request_type_name)
      require 'deas/route'
      Deas::Route.new(http_method, path, proxies).tap{ |r| self.routes.push(r) }
    end

    class HandlerProxies

      attr_reader :default_type

      def initialize(proxies, default_name)
        @proxies = proxies
        @default_type = default_name
      end

      def [](type)
        @proxies[type] || @proxies[@default_type] || raise(HandlerProxyNotFound)
      end

      def each(&block)
        @proxies.each(&block)
      end

      def empty?
        @proxies.empty?
      end

    end

    RequestType = Struct.new(:name, :proc)

  end

end

