require 'deas/redirect_proxy'
require 'deas/route_proxy'
require 'deas/route'
require 'deas/url'

module Deas
  class Router

    attr_accessor :urls, :routes

    def initialize(&block)
      @urls, @routes = {}, []
      self.instance_eval(&block) if !block.nil?
    end

    def view_handler_ns(value = nil)
      @view_handler_ns = value if !value.nil?
      @view_handler_ns
    end

    def base_url(value = nil)
      @base_url = value if !value.nil?
      @base_url
    end

    def url(name, path)
      if !path.kind_of?(::String)
        raise ArgumentError, "invalid path `#{path.inspect}` - "\
                             "can only provide a url name with String paths"
      end
      add_url(name.to_sym, path)
    end

    def url_for(name, *args)
      url = self.urls[name.to_sym]
      raise ArgumentError, "no route named `#{name.to_sym.inspect}`" unless url

      "#{base_url}#{url.path_for(*args)}"
    end

    def get(path, handler_name);    self.route(:get,    path, handler_name); end
    def post(path, handler_name);   self.route(:post,   path, handler_name); end
    def put(path, handler_name);    self.route(:put,    path, handler_name); end
    def patch(path, handler_name);  self.route(:patch,  path, handler_name); end
    def delete(path, handler_name); self.route(:delete, path, handler_name); end

    def route(http_method, from_path, handler_class_name)
      if self.view_handler_ns && !(handler_class_name =~ /^::/)
        handler_class_name = "#{self.view_handler_ns}::#{handler_class_name}"
      end
      proxy = Deas::RouteProxy.new(handler_class_name)

      from_url = self.urls[from_path]
      from_url_path = from_url.path if from_url
      add_route(http_method, "#{base_url}#{from_url_path || from_path}", proxy)
    end

    def redirect(from_path, to_path = nil, &block)
      to_url = self.urls[to_path]
      if to_path.kind_of?(::Symbol) && to_url.nil?
        raise ArgumentError, "no url named `#{to_path.inspect}`"
      end
      proxy = Deas::RedirectProxy.new(to_url || to_path, &block)

      from_url = self.urls[from_path]
      from_url_path = from_url.path if from_url
      add_route(:get, from_url_path || from_path, proxy)
    end

    private

    def add_url(name, path)
      self.urls[name] = Deas::Url.new(name, path)
    end

    def add_route(http_method, path, proxy)
      Deas::Route.new(http_method, path, proxy).tap{ |r| self.routes.push(r) }
    end

  end

end

