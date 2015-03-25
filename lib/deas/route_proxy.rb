require 'deas/exceptions'
require 'deas/handler_proxy'

module Deas

  class RouteProxy < HandlerProxy

    def initialize(handler_class_name, view_handler_ns = nil)
      raise(NoHandlerClassError.new(handler_class_name)) if handler_class_name.nil?

      if view_handler_ns && !(handler_class_name =~ /^::/)
        handler_class_name = "#{view_handler_ns}::#{handler_class_name}"
      end
      super(handler_class_name)
    end

    def validate!
      @handler_class = constantize(self.handler_class_name).tap do |handler_class|
        raise(NoHandlerClassError.new(self.handler_class_name)) if !handler_class
      end
    end

    private

    def constantize(class_name)
      names = class_name.to_s.split('::').reject{ |name| name.empty? }
      klass = names.inject(Object){ |constant, name| constant.const_get(name) }
      klass == Object ? false : klass
    rescue NameError
      false
    end

  end

end
